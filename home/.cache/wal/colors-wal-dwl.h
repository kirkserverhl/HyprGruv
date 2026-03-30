/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x1b1e25ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc6c6c8ff, 0x1b1e25ff, 0x626878ff },
	[SchemeSel]  = { 0xc6c6c8ff, 0x6E8A93ff, 0x637A86ff },
	[SchemeUrg]  = { 0xc6c6c8ff, 0x637A86ff, 0x6E8A93ff },
};
