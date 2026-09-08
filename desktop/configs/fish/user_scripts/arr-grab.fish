# Grab one specific release from Radarr/Sonarr by its TorrentDay URL.
#
#   arr-grab <torrentday-url|id> movie   <movie-id>
#   arr-grab <torrentday-url|id> episode <episode-id>
#   arr-grab <torrentday-url|id> season  <series-id> <season-number>
#
# Radarr/Sonarr resolve a release guid against the results of a recent search,
# so this always runs the manual search first, then force-grabs the matching
# release — rejections (seeders, quality profile) are printed, not obeyed.
#
# ponytail: TorrentDay only. Its guid *is* the details URL, which is what makes
# matching on the id work; other indexers use their own guid scheme.
function arr-grab -d "Grab a specific TorrentDay release via managarr"
    set -l td (string match -rg '(?:id=)?(\d+)$' -- "$argv[1]")
    set -l mode $argv[2]
    set -l id $argv[3]

    if test -z "$td"; or not string match -qr '^\d+$' -- "$id"
        echo "usage: arr-grab <torrentday-url|id> movie|episode|season <id> [season]" >&2
        return 2
    end

    set -l search
    set -l grab
    switch $mode
        case movie
            set search managarr radarr manual-search --movie-id $id
            set grab managarr radarr download-release --movie-id $id
        case episode
            set search managarr sonarr manual-search episode --episode-id $id
            set grab managarr sonarr download episode --episode-id $id
        case season
            if not string match -qr '^\d+$' -- "$argv[4]"
                echo "arr-grab: season mode needs a season number" >&2
                return 2
            end
            set search managarr sonarr manual-search season --series-id $id --season-number $argv[4]
            set grab managarr sonarr download season --series-id $id --season-number $argv[4]
        case '*'
            echo "usage: arr-grab <torrentday-url|id> movie|episode|season <id> [season]" >&2
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
