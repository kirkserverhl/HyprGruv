static const char norm_fg[] = "#c2c7c3";
static const char norm_bg[] = "#0d2010";
static const char norm_border[] = "#5d7160";

static const char sel_fg[] = "#c2c7c3";
static const char sel_bg[] = "#40778B";
static const char sel_border[] = "#c2c7c3";

static const char urg_fg[] = "#c2c7c3";
static const char urg_bg[] = "#B79171";
static const char urg_border[] = "#B79171";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
