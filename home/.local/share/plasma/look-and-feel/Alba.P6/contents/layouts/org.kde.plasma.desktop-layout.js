/*******Panel Top*********/
paneltop = new Panel
paneltop.hiding = "none"
paneltop.location = "top"
paneltop.height = 26
paneltop.lengthMode = "fill"
paneltop.floating = 1

paneltop.addWidget("org.kde.plasma.marginsseparator")
paneltop.addWidget("org.kde.plasma.kickoff")
paneltop.addWidget("org.kde.plasma.appmenu")
paneltop.addWidget("org.kde.plasma.panelspacer")
paneltop.addWidget("Minimal.chaac.weather")

var systraprev = paneltop.addWidget("org.kde.plasma.systemtray")
var SystrayContainmentId = systraprev.readConfig("SystrayContainmentId")
const systray = desktopById(SystrayContainmentId)
systray.currentConfigGroup = ["General"]
let ListTrays = systray.readConfig("extraItems")
let ListTrays2 = ListTrays.replace(",org.kde.plasma.notifications", "")
systray.writeConfig("extraItems", ListTrays2)
systray.writeConfig("iconSpacing", 1)

paneltop_clock = paneltop.addWidget("org.kde.plasma.digitalclock")
paneltop_clock.currentConfigGroup = ["Appearance"]
paneltop_clock.writeConfig("showDate", "false")
paneltop_clock.writeConfig("use24hFormat", '0')
paneltop_clock.writeConfig("fontStyleName", "bold")
paneltop_clock.writeConfig("autoFontAndSize", "false")
paneltop_clock.writeConfig("fontWeight", 700)
paneltop_clock.writeConfig("use24hFormat", "0")

paneltop.addWidget("org.kde.milou")
paneltop.addWidget("org.kde.plasma.notifications")
paneltop.addWidget("org.kde.plasma.marginsseparator")
            /****************************/
panelbottom = new Panel
panelbottom.location = "bottom"
panelbottom.height = 66
panelbottom.alignment = "center"
panelbottom.hiding = "dodgewindows"
panelbottom.lengthMode = "fit"
panelbottom.floating = 1
panelbottom.addWidget("org.kde.plasma.marginsseparator")
panelbottom.addWidget("org.kde.plasma.icontasks")
panelbottom.addWidget("org.kde.plasma.marginsseparator")

/* accent color config*/
ColorAccetFile = ConfigFile("kdeglobals")
ColorAccetFile.group = "General"
ColorAccetFile.writeEntry("accentColorFromWallpaper", "true")


/*Buttons of aurorae*/
Buttons = ConfigFile("kwinrc")
Buttons.group = "org.kde.kdecoration2"
Buttons.writeEntry("ButtonsOnRight", "")
Buttons.writeEntry("ButtonsOnLeft", "XAI")
/*Clock, Weather and Music Widget*/
let desktopsArray = desktopsForActivity(currentActivity());
for( var j = 0; j < desktopsArray.length; j++) {
var desktopByClock = desktopsArray[j]
}
const NumX = Number(((screenGeometry(desktopByClock).width)-404)/2)
const NumY = 80
var clockANDweather = desktopByClock.addWidget("zayron.almanac", NumX, NumY, 404, 404)

clockANDweather.currentConfigGroup = ["General"]
clockANDweather.writeConfig("desingone", "true")

splash = ConfigFile("ksplashrc")
splash.group = "KSplash"
splash.writeEntry("Theme", "Kde.Splash.Dinamic")

plasma.loadSerializedLayout(layout);
