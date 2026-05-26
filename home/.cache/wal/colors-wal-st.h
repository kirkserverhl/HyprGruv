const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0a1018", /* black   */
  [1] = "#837C78", /* red     */
  [2] = "#7C837E", /* green   */
  [3] = "#89827D", /* yellow  */
  [4] = "#968F89", /* blue    */
  [5] = "#A39C95", /* magenta */
  [6] = "#AAA39C", /* cyan    */
  [7] = "#c1c3c5", /* white   */

  /* 8 bright colors */
  [8]  = "#59626d",  /* black   */
  [9]  = "#837C78",  /* red     */
  [10] = "#7C837E", /* green   */
  [11] = "#89827D", /* yellow  */
  [12] = "#968F89", /* blue    */
  [13] = "#A39C95", /* magenta */
  [14] = "#AAA39C", /* cyan    */
  [15] = "#c1c3c5", /* white   */

  /* special colors */
  [256] = "#0a1018", /* background */
  [257] = "#c1c3c5", /* foreground */
  [258] = "#c1c3c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
