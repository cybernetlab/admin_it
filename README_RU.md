# AdminIt

Административный бэкенд для Rails.

# Установка

```sh
gem install admin_it
```

или используя `bundler`:

```ruby
# Gemfile
gem 'admin_it'
```

```sh
bundle install
```

# Настройка

Конфигурация производится в файле `config/initializers/admin_it.rb`. На данный момент доступны следующие переменные:

`config.root`: папка, содержащая определения ресурсов и другие настройки. По умолчанию: `app/admin_it`.

`config.controller`: класс контроллера, от которого наследуются все контроллеры, используемые библиотекой `admin_it`. По умолчанию для Rails: `ActionController::Base`.

# Использование

Библиотека оперирует такими понятиями, как:

* **Ресурс (resource)** - набор данных, который можно просматривать или изменять. Как правило, ресурс соответствует таблице базы данных. Для каждого ресурса библиотека создаёт отдельный класс контроллера.
* **Контекст (context)** - представление данных, или форма отображения данных. Контекст может быть для отдельной записи (`единичный контекст`) или для набора данных (`множественный контекст`). На данный момент библиотека предоставляет следующие контексты:
    - единичные:
        + `show` - отображение или удаление записи
        + `edit` - форма для редактирования записи
        + `new` - форма для создания записи
    - множественные:
        + `table` - таблица данных
        + `tiles` - набор плиток
        + `list` - список (пока не работает)
* **Поле (field)** - представляет поле (колонку) данных. Имеет следующие атрибуты:
    - readable
    - writable
    - visible
* **Фильтр (filter)** - фильтр данных. Пока не закончено.

Для создания интерфейса управления данными, необходимо определить ресурс. Делается это в файле с расширением `.rb` в папке, указанной в конфигурации, например:

```ruby
AdminIt.resource :location do
  icon 'globe'

  use_contexts except: :list

  collection do
    use_fields except: %i(created_at updated_at geo_point geo_data okato
                          kladr_code lowcase_name short_name area_children
                          region_children region area)
    use_filters :type_name_value, :level_value
  end

  context :tiles do
    header :name
  end

  context :table do
    use_fields :name, :level, :*
  end
end
```

В данном файле создается ресурс для данных класса `Location`. Ресурс использует для отображения иконку "глобус". (Все иконки можно найти [здесь](http://fortawesome.github.io/Font-Awesome/icons/) - имена необходимо указывать без суффикса `fa-`).

Далее указывается, что не нужно использовать (использовать все, кроме) контекст `:list`, посокльку его описание ещё не закончено.

Далее выполняется блок для всех множественных контекстов (поскольку `:list` исключён, то это `:table` и `:tiles`). Т.е. все множественные контексты будут использовать указанные в данном блоке настройки. В нашем случае это сокращенный список полей для удобства отображения и также, сокращённый список фильтров, имеющиё смысл в данном контексте.

Далее идет индивидуальная настройка каждого контекста (не указанные явно контексты принимают все значения по-умолчанию).

Для контекста `:tiles` указывается имя поля, служащее заголоком плитки

Для контекста `:table` указывается порядок следования полей: сначала `:name`, затем `:level`, затем все остальные в порядке по-умолчанию. Символ `:*` заменяется на все имеющиеся для данного контекста поля, не указанные в команде явно.

# Планы

* Поркытие тестами
* Редактирование/создание записей

## Далёкие планы

* Поддержка Sinatra

# Изменения

`1.0.10`

* добавлен индикатор сортировки в заголовках таблиц

`1.0.9`

* добавлена кнопка фильтров в заголоки таблиц

`1.0.8`

* полностью переработан код DSL
* увеличено покрытие тестами
* добавлена возможность выбора набора фильтров для контекста

`1.0.7`

* исправлено удаление записей
* добавлено подтверждение удаления
* налажено редактирование и создание простых записей

`1.0.6`

* исправлено: [#1](/../../issues/1)

`1.0.5`

* исправлено: font-awesome asset path

`1.0.4`

* исправлено: font-awesome

`1.0.3`

* исправлено: assets

`1.0.2`

* маршруты перенесены в папку config
* исправлены проблемы с pundit и devise

`1.0.1`

* исправлена ссылка на библиотеку wrap_it

`1.0.0` - пре-релиз

* поддержка active_record
* фильтры
* сортировка

`0.0.1` - first version

# Лицензия

The MIT License (MIT)

Copyright (c) 2014 Alexey Ovchinnikov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
