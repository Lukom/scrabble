Scrabble::Application.routes.draw do

  resource :home, controller: :home do
    collection do
      get :two_letter_words
      get :three_letter_words
      get :four_letter_words
      get :words_with_g
      get :riddles
      get :g_stats
    end
  end

  root :to => 'home#riddles'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
