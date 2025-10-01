const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0f1010", /* black   */
  [1] = "#777B72", /* red     */
  [2] = "#948B77", /* green   */
  [3] = "#8FC17B", /* yellow  */
  [4] = "#3E8285", /* blue    */
  [5] = "#458588", /* magenta */
  [6] = "#749D91", /* cyan    */
  [7] = "#cacabe", /* white   */

  /* 8 bright colors */
  [8]  = "#8d8d85",  /* black   */
  [9]  = "#777B72",  /* red     */
  [10] = "#948B77", /* green   */
  [11] = "#8FC17B", /* yellow  */
  [12] = "#3E8285", /* blue    */
  [13] = "#458588", /* magenta */
  [14] = "#749D91", /* cyan    */
  [15] = "#cacabe", /* white   */

  /* special colors */
  [256] = "#0f1010", /* background */
  [257] = "#cacabe", /* foreground */
  [258] = "#cacabe",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
