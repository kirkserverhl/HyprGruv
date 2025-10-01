static const char norm_fg[] = "#e5e0cf";
static const char norm_bg[] = "#1e1d1c";
static const char norm_border[] = "#a09c90";

static const char sel_fg[] = "#e5e0cf";
static const char sel_bg[] = "#A0967F";
static const char sel_border[] = "#e5e0cf";

static const char urg_fg[] = "#e5e0cf";
static const char urg_bg[] = "#928B78";
static const char urg_border[] = "#928B78";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
