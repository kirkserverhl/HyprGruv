/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x1e1d1cff);
static const float bordercolor[]           = COLOR(0xA0967Fff);
static const float focuscolor[]            = COLOR(0x928B78ff);
static const float urgentcolor[]           = COLOR(0x9F9B86ff);
