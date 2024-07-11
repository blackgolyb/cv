#!/bin/bash

# Вихід при помилці
set -e

# Задаємо змінні
TARGET_DIR="target"
BRANCH="release"
TAG="v$1"
COMMIT_MESSAGE="added new version $TAG"


# Перехід до теки з вашим репозиторієм
REPO_DIR=$(git rev-parse --show-toplevel)
cd $REPO_DIR || { echo "Тека репозиторію не знайдена!"; exit 1; }
TARGET_DIR="$REPO_DIR/$TARGET_DIR"

# Створення нової тимчасової теки для target
TEMP_DIR=$(mktemp -d)

# Ініціалізація нового git репозиторію у тимчасовій теці
cd $TEMP_DIR
git init

# Додавання віддаленого репозиторію
git remote add origin $(git -C $REPO_DIR config --get remote.origin.url)

# Витягування гілки release
git fetch origin $BRANCH
git checkout -b $BRANCH -f origin/$BRANCH

# Копіювання вмісту теки target до тимчасової теки
git rm -rf .
cp -rT $TARGET_DIR $TEMP_DIR

# Додавання змін з теки target
git add .

# Перевірка, чи є що комітити
if git diff-index --quiet HEAD --; then
    echo "Немає змін для коміту."
    exit 0
fi

# Створення коміту з повідомленням
git commit -m "$COMMIT_MESSAGE"

# Додавання тега версії
git tag $TAG

# Пуш змін до віддаленого репозиторію
git push origin $BRANCH
git push origin $TAG

# Видалення тимчасової теки
rm -rf $TEMP_DIR

echo "Зміни додано і позначено тегом $TAG"
