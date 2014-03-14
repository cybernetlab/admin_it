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


# Использование

# Планы

* Поркытие тестами
* Редактирование/создание записей

## Далёкие планы

* Поддержка Sinatra

# Изменения

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
