const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0a0c0d", /* black   */
  [1] = "#808071", /* red     */
  [2] = "#898979", /* green   */
  [3] = "#A7A794", /* yellow  */
  [4] = "#C1BEA9", /* blue    */
  [5] = "#CECCB5", /* magenta */
  [6] = "#DDDBC4", /* cyan    */
  [7] = "#f1efe1", /* white   */

  /* 8 bright colors */
  [8]  = "#a8a79d",  /* black   */
  [9]  = "#808071",  /* red     */
  [10] = "#898979", /* green   */
  [11] = "#A7A794", /* yellow  */
  [12] = "#C1BEA9", /* blue    */
  [13] = "#CECCB5", /* magenta */
  [14] = "#DDDBC4", /* cyan    */
  [15] = "#f1efe1", /* white   */

  /* special colors */
  [256] = "#0a0c0d", /* background */
  [257] = "#f1efe1", /* foreground */
  [258] = "#f1efe1",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
