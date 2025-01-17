# Simple Stack

Simple Stack is an opinionated app generator and full-stack framework for creating web apps at hyper-speed. It is based on the idea that design simplicity should be first-class development goal.

## Local development

```
brew tap johnreitano/simplestack
brew install simplestack
simplestack hello_world
cd hello_world # take a look at the generated code
# then browse to http://localhost:4000
```

## Deploying to heroku

```
make deploy
```

# Primary Components

    * Front end
        * HTML/CSS
        * Bootstrap
        * ERB
        * Turbo
    * Backend
        * Ruby on Rails
        * Highlighted gems
            * Hotwire
            * Devise (coming soon)
            * Pundit (coming soon)
            * Sidekiq (coming soon)
        * Postgres
        * Redis
    * Deployment
        * Heroku
        * AWS  (coming soon)
        * Azure  (coming soon)
    * Devtools/Miscelleanous
        * Docker & Docker Compose
        * Minitest
        * Rubocop

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
