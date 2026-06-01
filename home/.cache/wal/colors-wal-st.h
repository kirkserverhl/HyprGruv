const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#101119", /* black   */
  [1] = "#5E6A83", /* red     */
  [2] = "#71748A", /* green   */
  [3] = "#887A8E", /* yellow  */
  [4] = "#7B849C", /* blue    */
  [5] = "#9793AA", /* magenta */
  [6] = "#ACAECF", /* cyan    */
  [7] = "#c3c3c5", /* white   */

  /* 8 bright colors */
  [8]  = "#5b5f70",  /* black   */
  [9]  = "#5E6A83",  /* red     */
  [10] = "#71748A", /* green   */
  [11] = "#887A8E", /* yellow  */
  [12] = "#7B849C", /* blue    */
  [13] = "#9793AA", /* magenta */
  [14] = "#ACAECF", /* cyan    */
  [15] = "#c3c3c5", /* white   */

  /* special colors */
  [256] = "#101119", /* background */
  [257] = "#c3c3c5", /* foreground */
  [258] = "#c3c3c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
