# GCPassesFix

**LegacyReborn** · твик для джейлбрейкнутых **iOS 5 – 7** (armv7/armv7s)

Чинит две вещи на старых iOS, собрав методы из гайдов [bag.xml](https://developer.bag-xml.com/guides) в один `.deb`:

| Что | Как |
|---|---|
| **Game Center** — не входит из-за просроченных корневых сертификатов и залежавшегося состояния входа | профиль с актуальными корневыми сертификатами + обратимый сброс состояния Game Center / iTunes Store / Setup |
| **Passbook (Passes)** — отвергает пропуска с неверной, просроченной или изменённой подписью | патч PassKit, принимающий любые `.pkpass` (на основе [SigPass](https://github.com/bag-xml/SigPass)) |

**Установка**: Cydia-репозиторий LegacyReborn — `http://repo.legacyreborn.cfd/` (пакет `cfd.legacyreborn.gcpassesfix`), или `.deb` со [страницы релизов](https://github.com/LR-Vensuki/GCPassesFix/releases).

После установки — **Настройки → GCPassesFix**.

## Game Center

На старых iOS Game Center перестал входить после того, как Apple сменила корневые сертификаты и серверы. Починка в два шага (кнопки в настройках):

1. **Корневые сертификаты.** Пакет несёт профиль `GCPassesFix-Roots.mobileconfig` с 39 актуальными корневыми и промежуточными сертификатами (Apple, Amazon, DigiCert, GlobalSign, GTS, USERTrust, Entrust, ISRG, Apple WWDR). «Install Root Certificates» кладёт его в `/var/mobile/Documents`, дальше профиль ставится тапом (Filza или письмо самому себе) и принимается в «Настройки → Профиль». Набор — как в гайде bag.xml ([tlsroot.litten.ca](https://tlsroot.litten.ca)); просрочённые сертификаты в сборку не попадают (их отбирает `tools/fetch-certs.sh`).
2. **Сброс состояния входа.** «Reset Sign-in State» делает бэкап и чистит настройки и кэши Game Center, iTunes Store и мастера первого запуска. После перезагрузки устройство открывает **Setup**, где вы входите в Apple ID заново.

Всё удаляемое сперва копируется в `/var/mobile/Library/GCPassesFix/backups`, «Restore Last Backup» возвращает назад. Пропуска, приложения и файлы не трогаются.

Метод Game Center — из гайда [developer.bag-xml.com/guides/gamecenter](https://developer.bag-xml.com/guides/gamecenter) (автор fifiisawesum).

## Passbook (Passes)

Старый Passbook отвергает любой пропуск с неверной, просроченной или изменённой подписью, а новый без платного аккаунта разработчика сделать нельзя. Твик патчит PassKit: `.pkpass` принимаются без проверки подписи, контрольной суммы и статуса отзыва. Работает само.

Фикс пропусков основан на [SigPass](https://github.com/bag-xml/SigPass) от **bag.xml** и **ObscureMosquito** (GPLv3). Хуки (`PKPass`, `PKLocalPass`, `WDCardFileManager`, `WDNetworkTaskManager`) оставлены как в оригинале; добавлена только проверка наличия класса, чтобы на iOS 5 (где Passbook ещё нет) ничего не ломалось. Как делать свои пропуска — в гайде [developer.bag-xml.com/guides/passbook](https://developer.bag-xml.com/guides/passbook).

## Команды

От root:

```sh
gcpassesfix status     # что установлено, что осталось почистить, какие есть бэкапы
gcpassesfix certs      # подготовить профиль сертификатов к установке
gcpassesfix reset      # бэкап и очистка состояния Game Center / Store / Setup
gcpassesfix restore    # вернуть последний бэкап
```

## Сборка

Нужен [Theos](https://theos.dev) с SDK iPhoneOS 6.1 (цель `iphone:clang:6.1:5.0`, armv7/armv7s).

```sh
make package FINALPACKAGE=1
```

Перед упаковкой `tools/make-profile.py` пересобирает профиль сертификатов из `layout/usr/share/gcpassesfix/certs`. Обновить сами сертификаты: `tools/fetch-certs.sh` (нужен `openssl`). Иконки — `tools/make-icons.py` (нужен Pillow). Пакет сжимается gzip: dpkg на iOS 5–7 не умеет xz/zstd.

> Theos не собирает из путей с пробелами. Если каталог проекта содержит пробел, собирайте из копии/симлинка без пробелов.

## Структура

```
Tweak.x                              хуки PassKit (фикс пропусков, на основе SigPass)
GCPassesFix.plist                    фильтр Substrate (Passbook, SpringBoard, passd; Mode=Any)
helper/gcpassesfix-run.c             setuid-root запуск для кнопок в настройках
prefs/                               бандл настроек (кнопки: сертификаты, сброс, восстановление)
layout/usr/bin/gcpassesfix           сброс/восстановление состояния Game Center
layout/usr/share/gcpassesfix/certs/  корневые сертификаты (DER)
layout/usr/share/gcpassesfix/*.mobileconfig  профиль сертификатов (генерируется)
tools/                               fetch-certs.sh, make-profile.py, make-icons.py
depiction/                           описание пакета для Cydia-репозитория
```

## Благодарности

- **bag.xml** и **ObscureMosquito** — SigPass, на котором основан фикс пропусков (GPLv3).
- **fifiisawesum** и **bag.xml** — гайд по Game Center.
- **litten.ca** — актуальный набор корневых сертификатов.

## Лицензия

GPLv3 (как у SigPass, от которого наследуется фикс пропусков). См. [LICENSE](LICENSE).
