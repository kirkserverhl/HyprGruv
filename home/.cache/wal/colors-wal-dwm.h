static const char norm_fg[] = "#c3c3c5";
static const char norm_bg[] = "#111119";
static const char norm_border[] = "#5c5c70";

static const char sel_fg[] = "#c3c3c5";
static const char sel_bg[] = "#625D69";
static const char sel_border[] = "#c3c3c5";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
};
