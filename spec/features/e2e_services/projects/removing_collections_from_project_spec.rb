require 'spec_helper'

describe 'When viewing the project page with more than one collection', reset: false do
  before :all do
    load_page :search, project: ['C1000000969-DEV08', 'C1200187767-EDF_OPS'], env: :sit

    login
    wait_for_xhr

    click_link('My Project')
    wait_for_xhr
  end

  it 'shows multiple collection cards' do
    expect(page).to have_css('.collection-card', count: 2)
  end

  it 'displays 2 collections in the summary' do
    within '.project-stats .collection-count' do
      expect(page).to have_content('2 Collections')
    end
  end

  context 'When removing a collection' do
    before :all do
      collection_card = find('.collection-card', match: :first)

      collection_card.find('.remove').click
    end

    it 'shows only one collection card' do
      expect(page).to have_css('.collection-card', count: 1)
    end

    it 'displays 1 collection in the summary' do
      within '.project-stats .collection-count' do
        expect(page).to have_content('1 Collection')
      end
    end

    context 'When removing the last collection' do
      before :all do
        collection_card = find('.collection-card', match: :first)

        collection_card.find('.remove').click
      end

      it 'redirects the user back to the search page' do
        expect(page.current_url).to include('/search')
      end
    end
  end
end