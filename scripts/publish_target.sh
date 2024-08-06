#!/bin/bash

# Вихід при помилці
set -e

# Задаємо змінні
BUILD_DIR="build"
BRANCH="release"
TAG_PREFIX="v"


# Перехід до теки з вашим репозиторієм
REPO_DIR=$(git rev-parse --show-toplevel)
cd $REPO_DIR || { echo "Тека репозиторію не знайдена!"; exit 1; }
BUILD_DIR="$REPO_DIR/$BUILD_DIR"

# Створення нової тимчасової теки для build
TEMP_DIR=$(mktemp -d)

# Ініціалізація нового git репозиторію у тимчасовій теці
cd $TEMP_DIR
git init

# Додавання віддаленого репозиторію
git remote add origin $(git -C $REPO_DIR config --get remote.origin.url)

# Витягування гілки release
git fetch origin $BRANCH
git fetch --tags 
git checkout -b $BRANCH -f origin/$BRANCH

# Копіювання вмісту теки build до тимчасової теки
git rm -rf .
cp -rT $BUILD_DIR $TEMP_DIR

# Додавання змін з теки build
git add .

# Перевірка, чи є що комітити
if git diff-index --quiet HEAD --; then
    echo "Немає змін для коміту."
    exit 0
fi


if [ -n "$1" ]; then
    TAG="${TAG_PREFIX}$1"
else
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1) || echo "${TAG_PREFIX}0.0.0")
    if [ -z "$LATEST_TAG" ]; then
        TAG="${TAG_PREFIX}0.0.1"
    else
        # Збільшення версії
        IFS='.' read -r -a VERSION_PARTS <<< "${LATEST_TAG#"$TAG_PREFIX"}"
        VERSION_PARTS[2]=$((VERSION_PARTS[2]+1))
        TAG="${TAG_PREFIX}${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.${VERSION_PARTS[2]}"
    fi
fi

COMMIT_MESSAGE="added new version $TAG"


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
