# Simple Stack

Simple Stack is a full-stack framework for creating web apps at hyper-speed. It is based on
Ruby on Rails and Stimulus Reflex.

## Local development

```
    git clone https://github.com/johnreitano/simplestack.git
    cd simplestack
    ./simplestack.sh /path/to/my-project
    cd /path/to/my-project
    rails server -p
```

## Deploying to heroku

```
brew tap heroku/brew && brew install heroku
heroku login # follow prompts to login or sign up
TBD...
```

# Primary Components

    * Front end
        * HTML/CSS
        * Flexbox
        * Bootstrap
        * ERB
        * Turbolinks
        * StimulusReflex
    * Backend
        * Ruby on Rails
        * Highlighted gems
            * Stimulus Reflex
            * Devise
            * Pundit
            * Sidekiq
        * Postgres
        * Redis
    * Deployment (Coming soon)
        * Heroku
        * AWS
        * Azure
    * Devtools/Miscelleanous
        * Docker & Docker Compose
        * Minitest
        * Rubocop

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
