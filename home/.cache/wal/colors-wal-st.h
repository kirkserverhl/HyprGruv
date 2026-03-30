const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1b1e25", /* black   */
  [1] = "#637A86", /* red     */
  [2] = "#6E8A93", /* green   */
  [3] = "#7A9CA2", /* yellow  */
  [4] = "#7EA2A6", /* blue    */
  [5] = "#8FBBBB", /* magenta */
  [6] = "#92C0BE", /* cyan    */
  [7] = "#c6c6c8", /* white   */

  /* 8 bright colors */
  [8]  = "#626878",  /* black   */
  [9]  = "#637A86",  /* red     */
  [10] = "#6E8A93", /* green   */
  [11] = "#7A9CA2", /* yellow  */
  [12] = "#7EA2A6", /* blue    */
  [13] = "#8FBBBB", /* magenta */
  [14] = "#92C0BE", /* cyan    */
  [15] = "#c6c6c8", /* white   */

  /* special colors */
  [256] = "#1b1e25", /* background */
  [257] = "#c6c6c8", /* foreground */
  [258] = "#c6c6c8",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
