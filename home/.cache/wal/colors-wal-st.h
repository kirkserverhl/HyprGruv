const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0f1224", /* black   */
  [1] = "#5E6175", /* red     */
  [2] = "#64677B", /* green   */
  [3] = "#717489", /* yellow  */
  [4] = "#7E7E94", /* blue    */
  [5] = "#8A7B8F", /* magenta */
  [6] = "#9F8DA2", /* cyan    */
  [7] = "#c3c3c8", /* white   */

  /* 8 bright colors */
  [8]  = "#5e6074",  /* black   */
  [9]  = "#5E6175",  /* red     */
  [10] = "#64677B", /* green   */
  [11] = "#717489", /* yellow  */
  [12] = "#7E7E94", /* blue    */
  [13] = "#8A7B8F", /* magenta */
  [14] = "#9F8DA2", /* cyan    */
  [15] = "#c3c3c8", /* white   */

  /* special colors */
  [256] = "#0f1224", /* background */
  [257] = "#c3c3c8", /* foreground */
  [258] = "#c3c3c8",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
