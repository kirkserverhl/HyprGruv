const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#111119", /* black   */
  [1] = "#625D69", /* red     */
  [2] = "#5E6176", /* green   */
  [3] = "#63677C", /* yellow  */
  [4] = "#6E7288", /* blue    */
  [5] = "#847B84", /* magenta */
  [6] = "#7D8299", /* cyan    */
  [7] = "#c3c3c5", /* white   */

  /* 8 bright colors */
  [8]  = "#5c5c70",  /* black   */
  [9]  = "#625D69",  /* red     */
  [10] = "#5E6176", /* green   */
  [11] = "#63677C", /* yellow  */
  [12] = "#6E7288", /* blue    */
  [13] = "#847B84", /* magenta */
  [14] = "#7D8299", /* cyan    */
  [15] = "#c3c3c5", /* white   */

  /* special colors */
  [256] = "#111119", /* background */
  [257] = "#c3c3c5", /* foreground */
  [258] = "#c3c3c5",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
