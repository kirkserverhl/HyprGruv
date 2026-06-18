-- Smooth bezier animations (converted from conf/animations/default.conf).
-- The MD3 spring preset felt stiff/rigid on window open-move-close.

hl.config({ animations = { enabled = true } })

hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("winIn",     { type = "bezier", points = { {0.1, 1.1},  {0.1, 1.1}  } })
hl.curve("winOut",    { type = "bezier", points = { {0.3, -0.3}, {0, 1}      } })
hl.curve("liner",     { type = "bezier", points = { {1, 1},      {1, 1}      } })
hl.curve("overshot",  { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.5, 0},    {0.99, 0.99} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6, bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5, bezier = "winOut",    style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = false, speed = 2, bezier = "liner" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 3, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "wind", style = "slidevert" })