# Dodona

The Dodona project aims to provide a solution for the automatic testing of solutions for programming exercises.

Students can sign in with their UGent credentials after which an account is created automatically. On submission, their solutions gets stored on the server and a sandboxed background job is started to test the solution.

* Production version: http://dodona.ugent.be
* Development version: http://naos.ugent.be

## Development Setup

1. Install mysql
2. Create dodona user (with password 'dodona') with create database permissions.
3. Run `rake db:setup`
4. Start the server with `rails s`
    (If the server blocks, restart it.)
5. Create a user.
6. Log in as that user, for example by placing `sign_in User.first` in the `set_locale` function in `app/controllers/application_controller.rb`.You should remain logged in because a cookie is set.
7. Remove the line you just added.
