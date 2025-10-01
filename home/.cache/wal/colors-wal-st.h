const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1e1d1c", /* black   */
  [1] = "#928B78", /* red     */
  [2] = "#A0967F", /* green   */
  [3] = "#9F9B86", /* yellow  */
  [4] = "#B3AC91", /* blue    */
  [5] = "#C4BB9D", /* magenta */
  [6] = "#BAC0A6", /* cyan    */
  [7] = "#e5e0cf", /* white   */

  /* 8 bright colors */
  [8]  = "#a09c90",  /* black   */
  [9]  = "#928B78",  /* red     */
  [10] = "#A0967F", /* green   */
  [11] = "#9F9B86", /* yellow  */
  [12] = "#B3AC91", /* blue    */
  [13] = "#C4BB9D", /* magenta */
  [14] = "#BAC0A6", /* cyan    */
  [15] = "#e5e0cf", /* white   */

  /* special colors */
  [256] = "#1e1d1c", /* background */
  [257] = "#e5e0cf", /* foreground */
  [258] = "#e5e0cf",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
