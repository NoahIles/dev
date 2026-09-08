# Grab one specific release from Radarr/Sonarr by its TorrentDay URL.
#
#   arr-grab <torrentday-url|id> movie   <title|movie-id>
#   arr-grab <torrentday-url|id> season  <title|series-id> <season-number>
#   arr-grab <torrentday-url|id> episode <title|series-id> <SxxEyy>
#   arr-grab <torrentday-url|id> episode <episode-id>
#
# Radarr/Sonarr resolve a release guid against the results of a recent search,
# so this always runs the manual search first, then force-grabs the matching
# release — rejections (seeders, quality profile) are printed, not obeyed.
#
# ponytail: TorrentDay only. Its guid *is* the details URL, which is what makes
# matching on the id work; other indexers use their own guid scheme.

# Substring-match a library title to its id. A bare number passes straight
# through, so every caller can take either. Prints nothing on failure — the
# candidate list goes to stderr — so an empty result means "stop".
function __arr_match -d "Filter a Servarr library JSON by title substring and optional year"
    printf '%s\n' $argv[1] | jq -r --arg q "$argv[2]" --arg y "$argv[3]" '
        # Fold accents: managarr does not expose sortTitle, so "pokemon" would
        # otherwise miss "Pokémon".
        def fold: ascii_downcase
            | gsub("[àáâãäÀÁÂÃÄ]"; "a") | gsub("[èéêëÈÉÊË]"; "e")
            | gsub("[ìíîïÌÍÎÏ]"; "i")   | gsub("[òóôõöÒÓÔÕÖ]"; "o")
            | gsub("[ùúûüÙÚÛÜ]"; "u")   | gsub("[ñÑ]"; "n") | gsub("[çÇ]"; "c");
        .[] | select((.title | fold | contains($q | fold))
                     and ($y == "" or ((.year // 0) | tostring) == $y))
            | "\(.id)\t\(.title) (\(.year))"'
end

function __arr_resolve -d "Resolve a movie/series title to its Servarr id"
    set -l arr $argv[1]
    set -l query $argv[2]

    if string match -qr '^\d+$' -- "$query"
        echo $query
        return 0
    end

    set -l what movies
    test $arr = sonarr; and set what series
    set -l lib (managarr $arr list $what 2>/dev/null | string collect)

    set -l hits (__arr_match "$lib" "$query" "")

    # No hit? The query may carry a year the library title doesn't ("mayday 2026"
    # vs "Mayday"). Peel it off and use it as a year filter instead. Literal match
    # runs first so a title that really ends in a year — "Blade Runner 2049" —
    # still finds itself.
    if test (count $hits) -eq 0
        set -l year (string match -rg '[ .]((?:19|20)\d\d)$' -- "$query")
        if test -n "$year"
            set hits (__arr_match "$lib" (string replace -r '[ .](?:19|20)\d\d$' '' -- "$query") "$year")
        end
    end

    switch (count $hits)
        case 0
            echo "arr-grab: nothing in $arr matches \"$query\"" >&2
        case 1
            string split -f1 \t -- $hits[1]
        case '*'
            echo "arr-grab: \"$query\" is ambiguous —" >&2
            printf '  %s\n' $hits >&2
    end
end

function arr-grab -d "Grab a specific TorrentDay release via managarr"
    set -l usage "usage: arr-grab <torrentday-url|id> movie <title|id> | season <title|id> <n> | episode <title|id> <SxxEyy>"
    set -l td (string match -rg '(?:id=)?(\d+)$' -- "$argv[1]")
    set -l mode $argv[2]
    set -l target $argv[3]

    if test -z "$td" -o -z "$target"
        echo $usage >&2
        return 2
    end

    set -l search
    set -l grab
    switch $mode
        case movie
            set -l mid (__arr_resolve radarr "$target")
            test -n "$mid"; or return 1
            set search managarr radarr manual-search --movie-id $mid
            set grab managarr radarr download-release --movie-id $mid

        case season
            if not string match -qr '^\d+$' -- "$argv[4]"
                echo "arr-grab: season mode needs a season number" >&2
                return 2
            end
            set -l sid (__arr_resolve sonarr "$target")
            test -n "$sid"; or return 1
            set search managarr sonarr manual-search season --series-id $sid --season-number $argv[4]
            set grab managarr sonarr download season --series-id $sid --season-number $argv[4]

        case episode
            set -l eid
            if test (count $argv) -ge 4
                set -l se (string match -rgi '^s(\d+)e(\d+)$' -- "$argv[4]")
                if test (count $se) -ne 2
                    echo "arr-grab: episode needs SxxEyy, got \"$argv[4]\"" >&2
                    return 2
                end
                set -l sid (__arr_resolve sonarr "$target")
                test -n "$sid"; or return 1
                # --arg not --argjson: S03 is not valid JSON, "03" | tonumber is.
                set eid (managarr sonarr list episodes --series-id $sid 2>/dev/null \
                    | jq -r --arg s $se[1] --arg e $se[2] '.[]
                        | select(.seasonNumber == ($s|tonumber) and .episodeNumber == ($e|tonumber))
                        | .id')
                if test -z "$eid"
                    echo "arr-grab: no $argv[4] in that series" >&2
                    return 1
                end
            else if string match -qr '^\d+$' -- "$target"
                set eid $target
            else
                echo "arr-grab: episode needs <title|series-id> <SxxEyy>, or a bare episode id" >&2
                return 2
            end
            set search managarr sonarr manual-search episode --episode-id $eid
            set grab managarr sonarr download episode --episode-id $eid

        case '*'
            echo $usage >&2
            return 2
    end

    # managarr prints its progress line on stdout, so drop everything before the JSON.
    set -l hit ($search --disable-spinner | sed -n '/^\[/,$p' \
        | jq -c --arg td "id=$td" 'map(select(.guid | endswith($td))) | .[0] // empty')

    if test -z "$hit"
        echo "arr-grab: no release ending in id=$td in the search results" >&2
        return 1
    end

    echo $hit | jq -r '"grabbing: \(.title)\n  size: \(.size / 1073741824 | floor)G  seeders: \(.seeders)"'
    echo $hit | jq -r 'select(.rejected) | "  overriding: \(.rejections | join("; "))"'

    $grab --guid (echo $hit | jq -r .guid) --indexer-id (echo $hit | jq -r .indexerId)
end
