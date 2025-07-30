import tkinter as tk
import threading
import time
import numpy as np
import mss
import ctypes
from ultralytics import YOLO
import keyboard
import os
import sys

# --- CONFIG ---
model_dir = os.path.join(os.path.expanduser("~"), "Downloads", "ai aimbot")
model_path = os.path.join(model_dir, "best.pt")

if not os.path.isfile(model_path):
    print("didnt find best.pt")
    sys.exit(1)
else:
    print("found!")

MODEL_PATH = model_path

model = YOLO(MODEL_PATH)
FOV_RADIUS = 150
TARGET_FPS = 144

MOUSE_SPEED = 500
aim_assist_enabled = True
boxes_visible = True  # Controls ESP boxes visibility

screen_w, screen_h = 1920, 1080
center_x, center_y = screen_w // 2, screen_h // 2

# Define no-aim zone rectangle (adjust to your character's position)
# Format: (x0, y0, x1, y1)
no_aim_zone = (800, 900, 1100, 1100)  # <-- tweak these coordinates as needed

# --- CTYPES MOUSE ---
def move_mouse_relative(dx, dy):
    # 0x0001 = MOUSEEVENTF_MOVE
    ctypes.windll.user32.mouse_event(0x0001, int(dx), int(dy), 0, 5)

def get_mouse_pos():
    pt = ctypes.wintypes.POINT()
    ctypes.windll.user32.GetCursorPos(ctypes.byref(pt))
    return pt.x, pt.y

def rects_overlap(ax0, ay0, ax1, ay1, bx0, by0, bx1, by1):
    return not (ax1 < bx0 or ax0 > bx1 or ay1 < by0 or ay0 > by1)

# --- TK Overlay ---
root = tk.Tk()
root.title("Aim Assist Overlay & Config")
root.attributes("-topmost", True)
root.attributes("-transparentcolor", "black")
root.overrideredirect(True)
root.geometry(f"{screen_w}x{screen_h}+0+0")

canvas = tk.Canvas(root, width=screen_w, height=screen_h, bg="black", highlightthickness=0)
canvas.pack()

# FOV circle - always visible
fov_circle = canvas.create_oval(
    center_x - FOV_RADIUS, center_y - FOV_RADIUS,
    center_x + FOV_RADIUS, center_y + FOV_RADIUS,
    outline="green", width=2, tags="fov"
)

fps_label = canvas.create_text(100, 30, fill="white", font=("Consolas", 16), text="FPS: 0", tags="fps")

# --- Control Panel Frame (slider + toggles) ---
control_frame = tk.Frame(root, bg="black")
control_frame.place(x=10, y=10)

MOUSE_SPEED_var = tk.DoubleVar(value=MOUSE_SPEED)
aim_assist_enabled_var = tk.BooleanVar(value=aim_assist_enabled)
boxes_visible_var = tk.BooleanVar(value=boxes_visible)

def on_slider_change(value):
    global MOUSE_SPEED
    MOUSE_SPEED = float(value)

slider = tk.Scale(control_frame, from_=0, to=1000, orient=tk.HORIZONTAL, length=300,
                  command=on_slider_change, bg="black", fg="white",
                  troughcolor="gray", highlightthickness=0, variable=MOUSE_SPEED_var)
slider.pack()

def toggle_aim_assist():
    global aim_assist_enabled
    aim_assist_enabled = not aim_assist_enabled
    aim_assist_enabled_var.set(aim_assist_enabled)
    toggle_button.config(text="Aim Assist: ON" if aim_assist_enabled else "Aim Assist: OFF",
                         bg="darkgreen" if aim_assist_enabled else "darkred")

toggle_button = tk.Button(control_frame, text="Aim Assist: ON", command=toggle_aim_assist, bg="darkgreen", fg="white", font=("Consolas", 12))
toggle_button.pack(pady=5)

def toggle_boxes():
    global boxes_visible
    boxes_visible = not boxes_visible
    boxes_visible_var.set(boxes_visible)
    boxes_toggle_btn.config(text="Boxes: ON" if boxes_visible else "Boxes: OFF",
                           bg="darkgreen" if boxes_visible else "darkred")

boxes_toggle_btn = tk.Button(control_frame, text="Boxes: ON", command=toggle_boxes, bg="darkgreen", fg="white", font=("Consolas", 12))
boxes_toggle_btn.pack(pady=5)

# Control panel visibility toggle state
control_panel_visible = True

def toggle_control_panel():
    global control_panel_visible
    if control_panel_visible:
        control_frame.place_forget()
        control_panel_visible = False
    else:
        control_frame.place(x=10, y=10)
        control_panel_visible = True

# --- AI LOOP ---
def ai_loop():
    sct = mss.mss()
    monitor = sct.monitors[1]

    while True:
        start_time = time.time()
        img = np.array(sct.grab(monitor))[:, :, :3]

        results = model.predict(source=img, imgsz=736, device='cpu', verbose=False)[0]
        canvas.delete("box")

        best_target = None
        best_distance = float("inf")

        for box in results.boxes:
            x0, y0, x1b, y1b = box.xyxy[0].cpu().numpy()
            conf = float(box.conf[0])

            # Skip detections overlapping no-aim zone (your character)
            if rects_overlap(x0, y0, x1b, y1b, *no_aim_zone):
                continue

            cx = (x0 + x1b) / 2
            cy = (y0 + y1b) / 2

            dist = np.hypot(cx - center_x, cy - center_y)
            if dist < best_distance:
                best_distance = dist
                best_target = (cx, cy)

            if boxes_visible:
                canvas.create_rectangle(x0, y0, x1b, y1b, outline="red", width=2, tags="box")
                canvas.create_text(x0 + 5, y0 + 5, anchor="nw", text=f"{conf:.2f}", fill="white", font=("Consolas", 10), tags="box")

        if best_target and aim_assist_enabled:
            tx, ty = best_target
            current_x, current_y = get_mouse_pos()

            dx = tx - current_x
            dy = ty - current_y
            distance = np.hypot(dx, dy)

            if distance > 2:  # Deadzone
                step = MOUSE_SPEED / TARGET_FPS
                move_mouse_relative(np.clip(dx, -step, step), np.clip(dy, -step, step))

        elapsed = time.time() - start_time
        fps = int(1 / elapsed) if elapsed > 0 else 0
        canvas.itemconfig(fps_label, text=f"FPS: {fps}")

        time.sleep(max(0.001, 1 / TARGET_FPS - elapsed))

threading.Thread(target=ai_loop, daemon=True).start()
keyboard.add_hotkey('insert', toggle_control_panel)

root.mainloop()
