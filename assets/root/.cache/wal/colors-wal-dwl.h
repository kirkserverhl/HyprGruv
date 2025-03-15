/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x0f1010ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc3c3c3ff, 0x0f1010ff, 0x6c5959ff },
	[SchemeSel]  = { 0xc3c3c3ff, 0x948B77ff, 0x777B72ff },
	[SchemeUrg]  = { 0xc3c3c3ff, 0x777B72ff, 0x948B77ff },
};
