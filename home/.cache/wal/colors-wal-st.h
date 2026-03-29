const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0b1419", /* black   */
  [1] = "#808071", /* red     */
  [2] = "#898979", /* green   */
  [3] = "#A7A794", /* yellow  */
  [4] = "#C1BEA9", /* blue    */
  [5] = "#CECCB5", /* magenta */
  [6] = "#DDDBC4", /* cyan    */
  [7] = "#c2c4c5", /* white   */

  /* 8 bright colors */
  [8]  = "#5a676e",  /* black   */
  [9]  = "#808071",  /* red     */
  [10] = "#898979", /* green   */
  [11] = "#A7A794", /* yellow  */
  [12] = "#C1BEA9", /* blue    */
  [13] = "#CECCB5", /* magenta */
  [14] = "#DDDBC4", /* cyan    */
  [15] = "#c2c4c5", /* white   */

  /* special colors */
  [256] = "#0b1419", /* background */
  [257] = "#c2c4c5", /* foreground */
  [258] = "#c2c4c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
