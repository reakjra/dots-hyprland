pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string query: ""
    property string categories: "111" // general, anime, people
    property string purity: "100" // sfw, sketchy, nsfw
    property string sorting: "date_added"
    property string order: "desc"
    property string topRange: "1M"
    property string atleast: ""
    property string ratios: ""
    property int page: 1
    property int lastPage: 1
    property int totalResults: 0
    property bool loading: false
    property bool downloading: false
    property string downloadingId: ""
    property string seed: ""

    signal resultsReset()
    property ListModel results: ListModel {}

    readonly property string apiBase: "https://wallhaven.cc/api/v1"
    readonly property string cacheDir: `${Directories.wallhavenCache}`

    function load() {}

    function toRatio(w, h) {
        const common = [
            [16, 9], [16, 10], [21, 9], [32, 9],
            [4, 3], [5, 4], [3, 2], [1, 1],
            [5, 3], [2, 1], [3, 1],
        ]
        const r = w / h
        for (const [rw, rh] of common) {
            if (Math.abs(r - rw / rh) < 0.02) return `${rw}:${rh}`
        }
        function gcd(a, b) { return b === 0 ? a : gcd(b, a % b) }
        const g = gcd(w, h)
        const sw = w / g, sh = h / g
        if (sw <= 64 && sh <= 64) return `${sw}:${sh}`
        return `${r.toFixed(1)}:1`
    }

    function buildSearchUrl() {
        const params = []
        if (query) params.push(`q=${encodeURIComponent(query)}`)
        params.push(`categories=${categories}`)
        params.push(`purity=${purity}`)
        params.push(`sorting=${sorting}`)
        params.push(`order=${order}`)
        if (sorting === "toplist") params.push(`topRange=${topRange}`)
        if (atleast) params.push(`atleast=${atleast}`)
        if (ratios) params.push(`ratios=${ratios}`)
        params.push(`page=${page}`)
        if (seed) params.push(`seed=${seed}`)
        const apiKey = Config.options?.wallhaven?.apiKey ?? ""
        if (apiKey) params.push(`apikey=${apiKey}`)
        return `${apiBase}/search?${params.join("&")}`
    }

    function search(append = false, resetPage = true) {
        if (loading) return
        if (!append) {
            if (resetPage) page = 1
            results.clear()
            seed = ""
            resultsReset()
        }
        loading = true

        const url = buildSearchUrl()
        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            loading = false
            if (xhr.status !== 200) {
                console.error("[Wallhaven] Request failed:", xhr.status, xhr.statusText)
                return
            }
            try {
                const data = JSON.parse(xhr.responseText)
                const meta = data.meta
                lastPage = meta.last_page
                totalResults = meta.total
                if (meta.seed) seed = meta.seed
                for (const wp of data.data) {
                    results.append({
                        wallId: wp.id,
                        thumbUrl: wp.thumbs.large,
                        fullUrl: wp.path,
                        resolution: wp.resolution,
                        ratio: toRatio(wp.dimension_x, wp.dimension_y),
                        category: wp.category,
                        purity: wp.purity,
                        views: wp.views,
                        favorites: wp.favorites,
                        dimX: wp.dimension_x,
                        dimY: wp.dimension_y,
                    })
                }
            } catch (e) {
                console.error("[Wallhaven] Parse error:", e)
            }
        }
        xhr.send()
    }

    function loadMore() {
        if (page >= lastPage || loading) return
        page++
        search(true)
    }

    function random() {
        sorting = "random"
        seed = ""
        search()
    }

    Process {
        id: downloadProc
        property string targetPath
        running: false
        onExited: (exitCode, exitStatus) => {
            root.downloading = false
            root.downloadingId = ""
            if (exitCode === 0 && downloadProc.targetPath)
                Wallpapers.apply(downloadProc.targetPath)
            else
                console.error("[Wallhaven] Download failed:", exitCode)
        }
    }

    function applyWallpaper(fullUrl, wallId) {
        if (downloading) return
        const ext = fullUrl.split(".").pop()
        const targetPath = `${cacheDir}/${wallId}.${ext}`
        downloading = true
        downloadingId = wallId
        downloadProc.targetPath = targetPath
        downloadProc.command = [
            "bash", "-c",
            `mkdir -p '${cacheDir}' && curl -fsSL --compressed -o '${targetPath}' '${fullUrl}'`
        ]
        downloadProc.running = true
    }
}
