static const char norm_fg[] = "#c4c1c1";
static const char norm_bg[] = "#160909";
static const char norm_border[] = "#6c5959";

static const char sel_fg[] = "#c4c1c1";
static const char sel_bg[] = "#605F60";
static const char sel_border[] = "#c4c1c1";

static const char urg_fg[] = "#c4c1c1";
static const char urg_bg[] = "#4D4D4D";
static const char urg_border[] = "#4D4D4D";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
