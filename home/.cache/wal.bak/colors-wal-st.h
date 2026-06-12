const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101019", /* black   */
  [1] = "#887B91", /* red     */
  [2] = "#A594AA", /* green   */
  [3] = "#D5A6B4", /* yellow  */
  [4] = "#E7B4B2", /* blue    */
  [5] = "#EAC6BA", /* magenta */
  [6] = "#DABAC1", /* cyan    */
  [7] = "#c3c3c5", /* white   */

  /* 8 bright colors */
  [8]  = "#5b5b70",  /* black   */
  [9]  = "#887B91",  /* red     */
  [10] = "#A594AA", /* green   */
  [11] = "#D5A6B4", /* yellow  */
  [12] = "#E7B4B2", /* blue    */
  [13] = "#EAC6BA", /* magenta */
  [14] = "#DABAC1", /* cyan    */
  [15] = "#c3c3c5", /* white   */

  /* special colors */
  [256] = "#101019", /* background */
  [257] = "#c3c3c5", /* foreground */
  [258] = "#c3c3c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
