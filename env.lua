return {
    width = 384,
    height = 256,
    vsync = false,
    scale = 3,

    resizable = true,
    minwidth = 228,
    minheight = 228,

    fullscreen = false,
    fullscreenable = false,
    fullscreensave = false,

    font = false,
    fonts = {},

    mapspath = "maps",
    imagespath = "images/base",
    tilespath = "images/tiles",
    backgroundspath = "images/backgrounds",
    screenspath = "screens",

    showfps = false,
    showdrawcalls = false,
    showcursor = false,
    showwindow = false,
    showdebug = false,

    savequery = {    
        debug = { var="DEBUG", type="boolean", scope="global", default=true },
        invince = { var="INVINCE", type="boolean", scope="global", default=true },
        scale = { var="SCALE", type="number", scope="global", default=3, min=1, max=4, snap=1 },

        vsync = { var="VSYNC", type="boolean", scope="global", default=true },
        musicvol = { var="MUSICVOL", type="number", scope="global", default=50, min=0, max=100, snap=1 },
        sfxvol = { var="SFXVOL", type="number", scope="global", default=50, min=0, max=100, snap=1 },
        notutorial = { var="NOTUTORIAL", type="boolean", scope="global", default=false },
        skipcutscene = { var="SKIPCUTSCENE", type="boolean", scope="global", default=false },

        levelreached = { var="LEVELREACHED", type="mix", scope="global", default=1 },
        controls = { var="CONTROLS", type="table", scope="global", default={
            left="a", right="d", jump="space", rotateleft="q", rotateright="e", pause="escape", reset="backspace"
        }},
        ranks = { var="TOPRANKS", type="table", scope="global", default={
            {time=false, deaths=false}, {time=false, deaths=false}, {time=false, deaths=false}
        }}
    }
}