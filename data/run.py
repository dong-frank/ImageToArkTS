import os
import csv

IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.ico', '.svg'}

def is_image_file(filename: str) -> bool:
    ext = os.path.splitext(filename)[1].lower()
    return ext in IMAGE_EXTENSIONS

def count_images_in_folder(folder_path: str) -> int:
    """递归统计文件夹内所有图片数量"""
    count = 0
    for root, dirs, files in os.walk(folder_path):
        count += sum(1 for f in files if is_image_file(f))
    return count

def main():
    root = r"data\高清截图"   # 请修改为实际路径
    if not os.path.isdir(root):
        print(f"错误：根目录不存在 - {root}")
        return

    # 存储结果：列表元素为 (分类, 应用名, 图片数)
    results = []

    # 遍历第一级目录（分类）
    for category in os.listdir(root):
        category_path = os.path.join(root, category)
        if not os.path.isdir(category_path):
            continue
        # 遍历第二级目录（应用名）
        for app in os.listdir(category_path):
            app_path = os.path.join(category_path, app)
            if not os.path.isdir(app_path):
                continue
            img_count = count_images_in_folder(app_path)
            if img_count > 0:   # 只记录有图片的应用，也可去掉 if 显示 0
                results.append((category, app, img_count))

    if not results:
        print("未找到任何包含图片的应用目录。")
        return

    # 按分类、应用名排序
    results.sort(key=lambda x: (x[0], x[1]))

    # 控制台输出表格
    print(f"{'分类':<20} {'应用名':<30} {'图片数量':>10}")
    print("-" * 62)
    for cat, app, cnt in results:
        print(f"{cat:<20} {app:<30} {cnt:>10}")
    total = sum(cnt for _, _, cnt in results)
    print("-" * 62)
    print(f"{'总计':<20} {'':<30} {total:>10}")

    # 保存为 CSV 文件
    csv_path = os.path.join(root, "image_count_by_app.csv")
    with open(csv_path, "w", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["分类", "应用名", "图片数量"])
        writer.writerows(results)
        writer.writerow(["总计", "", total])
    print(f"\nCSV 文件已保存至：{csv_path}")

if __name__ == "__main__":
    main()