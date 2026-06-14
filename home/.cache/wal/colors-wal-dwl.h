/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x121212ff);
static const float bordercolor[]           = COLOR(0x8F3A2Bff);
static const float focuscolor[]            = COLOR(0x71342Aff);
static const float urgentcolor[]           = COLOR(0xAD3D29ff);
