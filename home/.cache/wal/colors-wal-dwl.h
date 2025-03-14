/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x0f0f0eff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3c3c2ff, 0x0f0f0eff, 0x6c6c58ff },
	[SchemeSel]  = { 0xc3c3c2ff, 0x8D8A76ff, 0xC8AE36ff },
	[SchemeUrg]  = { 0xc3c3c2ff, 0xC8AE36ff, 0x8D8A76ff },
};
