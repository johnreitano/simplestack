# Simple Stack

Simple Stack is an opinionated app generator and full-stack framework for creating web apps at hyper-speed. It is based on the idea that design simplicity should be first-class development goal.

## Local development

```
    brew tap johnreitano/simplestack
    brew install simplestack
    simplestack new-project
    cd new-project
    rails server -p
    # then browse to http://localhost:3000
```

## Deploying to heroku

```
brew tap heroku/brew && brew install heroku
heroku login # follow prompts to login or sign up
make deploy
```

# Primary Components

    * Front end
        * HTML/CSS
        * Flexbox
        * Bootstrap
        * ERB
        * Turbo
    * Backend
        * Ruby on Rails
        * Highlighted gems
            * Hotware
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
