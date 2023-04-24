# kscurses
## _Curses replacement on jai for my needs. Use at your own risk._

Currently available support :
- character input
- window resize handle
- text modifiers (bold, italic, underline, blinking, inverse, strikethrough), color256 support
- text/background color.
- arrows, escape key and some 
- saving and restoring the terminal
- exit with and crtl+C (optional).
- ui elements (empty, button, text block, selection list)
- multiple scenes and popups support
- events (ticks, input, window resize and user-defined events)
- ui can work both in single-thread mode and multi-thread mode
- 4 print modes:
- - ks_**method** : method prints directly terminal
- - t_**method** : method returns temporary string or string from constant data section
- - b_**method** : method prints to builder
- - c_**method**: method prints to canvas

demos list :
- basic print methods, canvas and graphic modes usage
- video (now uses events)
- shorter canvas usage
- ui : text buffer, buttons, selection list, groups, scenes
- ui : popup
- ui : line input
- events processing

Currently works only on linux (tested on gnome terminal).