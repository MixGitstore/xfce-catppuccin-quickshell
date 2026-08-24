#include <X11/Xlib.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

static int ignore_x_error(Display *display, XErrorEvent *event)
{
    (void) display;
    (void) event;
    return 0;
}

int main(int argc, char **argv)
{
    char *end = NULL;
    unsigned long parsed_window;
    Display *display;
    XEvent event;

    if (argc != 2) {
        return 2;
    }

    errno = 0;
    parsed_window = strtoul(argv[1], &end, 0);
    if (errno != 0 || end == argv[1] || *end != '\0' || parsed_window == 0) {
        return 2;
    }

    display = XOpenDisplay(NULL);
    if (display == NULL) {
        return 3;
    }

    XSetErrorHandler(ignore_x_error);
    XSelectInput(display, (Window) parsed_window, StructureNotifyMask);
    XSync(display, False);

    /* Also request an initial geometry check when the active window changes. */
    puts("geometry");
    fflush(stdout);

    for (;;) {
        XNextEvent(display, &event);
        if (event.type == DestroyNotify) {
            break;
        }
        if (event.type == ConfigureNotify
                || event.type == MapNotify
                || event.type == UnmapNotify) {
            puts("geometry");
            fflush(stdout);
        }
    }

    XCloseDisplay(display);
    return 0;
}
