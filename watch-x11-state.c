#include <X11/Xatom.h>
#include <X11/Xlib.h>

#include <stdio.h>

static Display *display;
static Window root_window;
static Window active_window = None;
static Atom net_active_window;
static Atom net_client_list;
static Atom net_wm_state;
static Atom net_wm_state_fullscreen;
static Atom net_wm_state_maximized_horz;
static Atom net_wm_state_maximized_vert;
static Atom net_frame_extents;

static int ignore_x_error(Display *unused_display, XErrorEvent *unused_event)
{
    (void) unused_display;
    (void) unused_event;
    return 0;
}

static Window read_active_window(void)
{
    Atom actual_type = None;
    int actual_format = 0;
    unsigned long item_count = 0;
    unsigned long bytes_after = 0;
    unsigned char *data = NULL;
    Window result = None;

    if (XGetWindowProperty(display, root_window, net_active_window,
            0, 1, False, XA_WINDOW, &actual_type, &actual_format,
            &item_count, &bytes_after, &data) == Success
            && actual_type == XA_WINDOW && actual_format == 32
            && item_count > 0 && data != NULL) {
        result = *((Window *) data);
    }

    if (data != NULL) {
        XFree(data);
    }
    return result;
}

static void emit_state(void)
{
    Atom actual_type = None;
    int actual_format = 0;
    unsigned long item_count = 0;
    unsigned long bytes_after = 0;
    unsigned char *data = NULL;
    int fullscreen = 0;
    int maximized_horz = 0;
    int maximized_vert = 0;

    if (active_window != None
            && XGetWindowProperty(display, active_window, net_wm_state,
                0, 1024, False, XA_ATOM, &actual_type, &actual_format,
                &item_count, &bytes_after, &data) == Success
            && actual_type == XA_ATOM && actual_format == 32
            && data != NULL) {
        Atom *states = (Atom *) data;
        unsigned long index;
        for (index = 0; index < item_count; ++index) {
            fullscreen |= states[index] == net_wm_state_fullscreen;
            maximized_horz |= states[index] == net_wm_state_maximized_horz;
            maximized_vert |= states[index] == net_wm_state_maximized_vert;
        }
    }

    if (data != NULL) {
        XFree(data);
    }
    printf("state\t%d\t%d\n", fullscreen,
        maximized_horz && maximized_vert);
}

static void select_active_window(Window next_window)
{
    if (active_window != None && active_window != root_window) {
        XSelectInput(display, active_window, NoEventMask);
    }

    active_window = next_window;
    if (active_window != None && active_window != root_window) {
        XSelectInput(display, active_window,
            PropertyChangeMask | StructureNotifyMask);
    }
    XSync(display, False);

    if (active_window == None) {
        puts("active\t0x0");
    } else {
        printf("active\t0x%lx\n", active_window);
    }
    emit_state();
    puts("geometry");
}

int main(void)
{
    XEvent event;

    display = XOpenDisplay(NULL);
    if (display == NULL) {
        return 3;
    }

    setvbuf(stdout, NULL, _IOLBF, 0);
    XSetErrorHandler(ignore_x_error);
    root_window = DefaultRootWindow(display);

    net_active_window = XInternAtom(display, "_NET_ACTIVE_WINDOW", False);
    // Membership changes only when a client is created or destroyed. Watching
    // _NET_CLIENT_LIST_STACKING here would also rescan every focus/raise and
    // could rebuild a taskbar button while it is being clicked.
    net_client_list = XInternAtom(display, "_NET_CLIENT_LIST", False);
    net_wm_state = XInternAtom(display, "_NET_WM_STATE", False);
    net_wm_state_fullscreen = XInternAtom(display,
        "_NET_WM_STATE_FULLSCREEN", False);
    net_wm_state_maximized_horz = XInternAtom(display,
        "_NET_WM_STATE_MAXIMIZED_HORZ", False);
    net_wm_state_maximized_vert = XInternAtom(display,
        "_NET_WM_STATE_MAXIMIZED_VERT", False);
    net_frame_extents = XInternAtom(display, "_NET_FRAME_EXTENTS", False);

    XSelectInput(display, root_window, PropertyChangeMask);
    select_active_window(read_active_window());
    puts("clients");

    for (;;) {
        XNextEvent(display, &event);

        if (event.type == PropertyNotify
                && event.xproperty.window == root_window) {
            if (event.xproperty.atom == net_active_window) {
                select_active_window(read_active_window());
            } else if (event.xproperty.atom == net_client_list) {
                puts("clients");
            }
            continue;
        }

        if (event.xany.window != active_window) {
            continue;
        }

        if (event.type == PropertyNotify) {
            if (event.xproperty.atom == net_wm_state) {
                emit_state();
            } else if (event.xproperty.atom == net_frame_extents) {
                puts("geometry");
            }
        } else if (event.type == ConfigureNotify
                || event.type == MapNotify || event.type == UnmapNotify) {
            puts("geometry");
        } else if (event.type == DestroyNotify) {
            select_active_window(read_active_window());
        }
    }
}
