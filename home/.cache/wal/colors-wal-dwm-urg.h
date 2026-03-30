static const char norm_fg[] = "#c6c6c8";
static const char norm_bg[] = "#1b1e25";
static const char norm_border[] = "#626878";

static const char sel_fg[] = "#c6c6c8";
static const char sel_bg[] = "#6E8A93";
static const char sel_border[] = "#c6c6c8";

static const char urg_fg[] = "#c6c6c8";
static const char urg_bg[] = "#637A86";
static const char urg_border[] = "#637A86";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
