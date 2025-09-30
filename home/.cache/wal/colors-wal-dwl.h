/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x101212ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3c3c3ff, 0x101212ff, 0x596d6dff },
	[SchemeSel]  = { 0xc3c3c3ff, 0x478789ff, 0x3F8288ff },
	[SchemeUrg]  = { 0xc3c3c3ff, 0x3F8288ff, 0x478789ff },
};
