import cv2
import numpy as np
import sys

# Video / Output path
video_path = "1080p_2Min.MP4"
output_file = "1080p_2Min_Dataset.txt"
use_roi = True


cap = cv2.VideoCapture(video_path)

ret, frame = cap.read()
if not ret:
    print("Failed to load video")
    exit()

# ROI Selection
if use_roi:
    roi = cv2.selectROI("Select ROI", frame, False)
    x_roi, y_roi, w_roi, h_roi = roi
    cv2.destroyWindow("Select ROI")
else:
    x_roi, y_roi, w_roi, h_roi = 0, 0, frame.shape[1], frame.shape[0]

# Controls
cv2.namedWindow("Controls")
cv2.createTrackbar("Blur", "Controls", 5, 20, lambda x: None)
cv2.createTrackbar("Morph", "Controls", 5, 20, lambda x: None)

print("Calibration mode:")
print("Adjust sliders until centroid is stable.")
print("Press 'r' to start processing, 'q' to quit.")

# CALIBRATION LOOP 
while True:
    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
    ret, frame = cap.read()
    if not ret:
        break

    frame_roi = frame[y_roi:y_roi+h_roi, x_roi:x_roi+w_roi]
    gray = cv2.cvtColor(frame_roi, cv2.COLOR_BGR2GRAY)

    blur_val = cv2.getTrackbarPos("Blur", "Controls")
    morph_val = cv2.getTrackbarPos("Morph", "Controls")

    if blur_val % 2 == 0:
        blur_val += 1
    blur_val = max(1, blur_val)

    gray_blur = cv2.GaussianBlur(gray, (blur_val, blur_val), 0)

    _, thresh = cv2.threshold(
        gray_blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )

    kernel = np.ones((max(1, morph_val), max(1, morph_val)), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)

    M = cv2.moments(thresh)

    display = frame_roi.copy()

    if M["m00"] != 0:
        cx = int(M["m10"] / M["m00"])
        cy = int(M["m01"] / M["m00"])
        cv2.circle(display, (cx, cy), 5, (0, 0, 255), -1)

    cv2.imshow("Original ROI", frame_roi)
    cv2.imshow("Threshold", thresh)
    cv2.imshow("Centroid", display)

    key = cv2.waitKey(30) & 0xFF

    if key == ord('q'):
        cap.release()
        cv2.destroyAllWindows()
        exit()
    elif key == ord('r'):
        print("Starting batch processing...")
        break

# Get video info
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
fps = cap.get(cv2.CAP_PROP_FPS)
if fps == 0:
    fps = 30

# Reset to beginning
cap.set(cv2.CAP_PROP_POS_FRAMES, 0)

centroids = []
frame_index = 0

last_cx, last_cy = None, None
nan_count = 0
# PROCESSING LOOP
while True:
    ret, frame = cap.read()
    if not ret:
        break

    if last_cx is None:
        last_cx, last_cy = 0, 0

    frame_roi = frame[y_roi:y_roi+h_roi, x_roi:x_roi+w_roi]
    gray = cv2.cvtColor(frame_roi, cv2.COLOR_BGR2GRAY)

    gray_blur = cv2.GaussianBlur(gray, (blur_val, blur_val), 0)

    _, thresh = cv2.threshold(
        gray_blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )

    kernel = np.ones((max(1, morph_val), max(1, morph_val)), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)

    M = cv2.moments(thresh)

    if M["m00"] != 0:
        cx = M["m10"] / M["m00"]
        cy = M["m01"] / M["m00"]
        last_cx, last_cy = cx, cy
    else:
        cx, cy = last_cx, last_cy
        nan_count += 1

    time_sec = frame_index / fps
    centroids.append((frame_index, time_sec, cx, cy))

    # Progress bar 
    progress = frame_index / total_frames
    bar_length = 30
    filled = int(bar_length * progress)
    bar = "#" * filled + "-" * (bar_length - filled)
    sys.stdout.write(f"\rProcessing: [{bar}] {progress*100:.1f}%")
    sys.stdout.flush()

    frame_index += 1

cap.release()
print("\nProcessing complete.")

centroids = np.array(centroids)

# Compute displacement
valid_idx = np.where(~np.isnan(centroids[:,2]))[0][0]
x0, y0 = centroids[valid_idx, 2], centroids[valid_idx, 3]

dx = centroids[:,2] - x0
dy = centroids[:,3] - y0

output_data = np.column_stack((
    centroids[:,0],
    centroids[:,1],
    centroids[:,2],
    centroids[:,3],
    dx,
    dy
))

# Save
header = "frame time_sec x y dx dy"

np.savetxt(output_file, output_data, header=header, fmt="%.6f")

print(f"Frames with detection failure: {nan_count}")
print(f"Saved data to {output_file}")
cv2.destroyAllWindows()