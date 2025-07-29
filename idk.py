import tkinter as tk
import threading
import time
import numpy as np
import mss
import torch
import cv2
from ultralytics import YOLO
import pyautogui

# --- CONFIG ---
MODEL_PATH = r"C:\Users\User\ultralytics\runs\detect\train11\weights\best.pt"
FOV_RADIUS = 150
TARGET_FPS = 144
MOUSE_SPEED = 1000 # pixels/sec

# --- INIT ---
model = YOLO(MODEL_PATH)
screen_w, screen_h = 1920, 1080
center_x, center_y = screen_w // 2, screen_h // 2
pyautogui.FAILSAFE = False

# TK Overlay
root = tk.Tk()
root.attributes("-topmost", True)
root.attributes("-transparentcolor", "black")
root.overrideredirect(True)
root.geometry(f"{screen_w}x{screen_h}+0+0")
canvas = tk.Canvas(root, width=screen_w, height=screen_h, bg="black", highlightthickness=0)
canvas.pack()

# Draw FOV circle
fov_circle = canvas.create_oval(
    center_x - FOV_RADIUS, center_y - FOV_RADIUS,
    center_x + FOV_RADIUS, center_y + FOV_RADIUS,
    outline="green", width=2, tags="fov"
)

# FPS label
fps_label = canvas.create_text(100, 30, fill="white", font=("Consolas", 16), text="FPS: 0", tags="fps")

def ai_loop():
    sct = mss.mss()
    monitor = sct.monitors[1]  # Laptop display

    while True:
        start_time = time.time()
        img = np.array(sct.grab(monitor))[:, :, :3]

        # YOLO detection
        results = model.predict(source=img, device=0, verbose=False)[0]

        # Remove previous boxes
        canvas.delete("box")

        best_target = None
        best_distance = float("inf")

        for box in results.boxes:
            x0, y0, x1b, y1b = box.xyxy[0].cpu().numpy()
            conf = float(box.conf[0])
            label = f"{conf:.2f}"

            cx = (x0 + x1b) / 2
            cy = (y0 + y1b) / 2

            # Get closest target to center (no FOV limit)
            dist = np.hypot(cx - center_x, cy - center_y)
            if dist < best_distance:
                best_distance = dist
                best_target = (cx, cy)

            # Draw box
            canvas.create_rectangle(x0, y0, x1b, y1b, outline="red", width=2, tags="box")
            canvas.create_text(x0 + 5, y0 + 5, anchor="nw", text=label, fill="white", font=("Consolas", 10), tags="box")

        # Move mouse to target
        if best_target:
            tx, ty = best_target
            current_x, current_y = pyautogui.position()

            dx = tx - current_x
            dy = ty - current_y
            distance = np.hypot(dx, dy)

            if distance > 2:  # Deadzone
                step = MOUSE_SPEED / TARGET_FPS
                move_x = current_x + np.clip(dx, -step, step)
                move_y = current_y + np.clip(dy, -step, step)
                pyautogui.moveTo(move_x, move_y)

        # Update FPS
        elapsed = time.time() - start_time
        fps = int(1 / elapsed) if elapsed > 0 else 0
        canvas.itemconfig(fps_label, text=f"FPS: {fps}")

        # Wait for next frame
        time.sleep(max(0.001, 1 / TARGET_FPS - elapsed))

# Start AI thread
threading.Thread(target=ai_loop, daemon=True).start()
root.mainloop()
