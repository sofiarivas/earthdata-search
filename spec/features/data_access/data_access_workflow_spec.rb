require "spec_helper"
require 'base64'

describe "Data Access workflow", reset: false do
  downloadable_collection_id = 'C203234523-LAADS'
  downloadable_collection_title = 'MODIS/Aqua Calibrated Radiances 5-Min L1B Swath 1km V006'

  test_collection_1 = 'C203234523-LAADS'
  test_collection_2 = 'C194001241-LPDAAC_ECS'
  test_collection_3 = 'C1000000561-NSIDC_ECS'
  
  collection_with_one_option = "C1000000020-LANCEAMSR2"
  collection_with_two_options = "C179003620-ORNL_DAAC"

  let(:echo_id) { "4C0390AF-BEE1-32C0-4606-66CAFDD4131D" }

  context "when a user has three or more collections within a project" do
    before(:all) do
      Capybara.reset_sessions!
      load_page :search, project: [test_collection_1, test_collection_2, test_collection_3], view: :project, ac: true
      login
      click_button "Download project data"
      wait_for_xhr
    end

    context "when clicking 'Stage for Delivery'on the first collection" do
      before(:all) do
        selection = find(:css, ".access-item:nth-child(1)").find(:css, ".access-item-selection")
        within selection do
          choose 'Stage for Delivery'
        end
        wait_for_xhr
      end
      it "displays the distribution options for the first collection" do
        form = find(:css, ".access-item:nth-child(1)").find(:css, ".access-form")
        synchronize(30) do
          expect(form).to have_css(".echoforms-control")
        end
      end
      context "and then clicking continue and selecting 'Customize' for the second collection" do
        before(:all) do
          click_button "Continue"

          within("#tooManyGranulesModal") do
            click_link("Continue")
          end

          wait_for_xhr
          selection = find(:css, ".access-item:nth-child(2)").find(:css, ".access-item-selection")
          within selection do
            choose 'Customize Product'
            wait_for_xhr
          end
        end
        it "displays the option subsettings for the second collection" do
          synchronize() do
            form = find(:css, ".access-item:nth-child(2)").find(:css, ".access-form")
            expect(form).to have_content("Include Metadata and Processing History")
          end
        end
        context "and then clicking continue and selecting 'Customize' for the third collection" do
          before(:all) do
            click_button "Continue"

            within("#tooManyGranulesModal") do
              click_link("Continue")
            end
            wait_for_xhr
          end
          it "displays the option subsetting for the third collection" do
            synchronize do
              selection = find(:css, ".access-item:nth-child(3)").find(:css, ".access-item-selection")
              within selection do
                choose 'Customize Product'
                wait_for_xhr
              end
            end
          end
        end
      end
    end
  end
  context "when a malicious user attempts an XSS attack using the data access back link" do
    before(:all) do
      load_page :root
      login
      visit "/data/configure?p=!#{downloadable_collection_id}&back=javascript:alert(%27ohai%27)//"
    end

    after :all do
      Capybara.reset_sessions!
    end

    it "uses a safe back link" do
      expect(page).to have_link("Back to Search Session")
      expect(page).to have_css("a[href^=\"/search/collections?p=!#{downloadable_collection_id}\"]")
    end
  end

  context "when the user is not logged in" do
    before(:all) do
      Capybara.reset_sessions!
      load_page :search, project: [downloadable_collection_id], view: :project
      wait_for_xhr
      click_button "Download project data"
      wait_for_xhr
    end

    after :all do
      Capybara.reset_sessions!
    end

    it "forces the user to login before showing data access page", intermittent: true do
      screenshot_path = "./tmp/screenshots/debug-#{Time.now.to_i}.png"
      expect(page).to have_content('EOSDIS Earthdata Login'), lambda {
        "Expect to see 'EOSDIS Earthdata Login' on the page. #{page.save_screenshot(screenshot_path)}"
        Rails.logger.info Base64.encode64(File.open(screenshot_path, "rb").read)}
    end
  end

  context "when the user is logged in" do
    before(:all) do
      load_page :search, {project: [downloadable_collection_id], view: :project, temporal: ['2014-07-10T00:00:00Z', '2014-07-10T03:59:59Z']}
      login
      click_button "Download project data"
      wait_for_xhr
    end

    after :all do
      Capybara.reset_sessions!
    end

    it "displays a link to return to search results" do
      expect(page).to have_link("Back to Search Session")
      expect(page).to have_css("a[href^=\"/search/project?p=!#{downloadable_collection_id}\"]")
    end

    context "when displaying options for the first of multiple collections" do
      after :all do
        reset_access_page
      end

      it "displays granule information" do
        expect(page).to have_content "49 Granules"
      end

      # it 'displays a "continue" button' do
      #   expect(page).to have_content "Continue"
      # end

      it 'displays no "back" button' do
        within(".data-access-content") do
          expect(page).to have_no_content "Back"
        end
      end

      context "when viewing granule list" do
        before :all do
          click_link 'Expand List'
          wait_for_xhr
        end

        after :all do
          click_link 'Hide List'
        end

        it "displays granule information" do
          expect(page).to have_content "MYD021KM.A2014191.0355.006.2014191161026.hdf"
        end

        it "displays more granules when scrolling" do
          page.execute_script "$('.granule-list div')[0].scrollTop = 10000"
          wait_for_xhr

          page.execute_script "$('.granule-list div')[0].scrollTop = 20000"
          wait_for_xhr

          expect(page).to have_css '.granule-list h5', count: 49
        end

        it "displays an option to download" do
          expect(page).to have_field('Download')
        end

        it "displays options provided by orders" do
          expect(page).to have_field('Stage for Delivery')
        end
      end

      # context 'and clicking the "continue" button' do
      #   before :all do
      #     choose "Download"
      #     click_button "Continue"
      #   end

      #   after :all do
      #     reset_access_page
      #   end

      #   it 'displays the next collection in the list' do
      #     expect(page).to have_content "Collection Only"
      #   end
      # end
    end

    # context "when displaying options for the last of multiple collections" do
    #   before :all do
    #     choose "Stage for Delivery"
    #     click_button "Continue"
    #   end

    #   after :all do
    #     reset_access_page
    #   end

    #   it "displays granule information" do
    #     expect(page).to have_content "Collection Only"
    #   end

    #   it 'displays a "continue" button to confirm contact information' do
    #     expect(page).to have_content "Continue"
    #   end

    #   it 'displays a "back" button' do
    #     within(".data-access-content") do
    #       expect(page).to have_content "Back"
    #     end
    #   end

    #   context 'and clicking the "back" button' do
    #     before :all do
    #       click_button "Back"
    #     end

    #     it 'displays the previous collection in the list' do
    #       expect(page).to have_content "49 Granules"
    #     end
    #   end
    # end

    # context "on the final collection's step when contact information is not required" do
    #   before :all do
    #     choose "Download"
    #     click_button "Continue"
    #   end

    #   after :all do
    #     reset_access_page
    #   end

    #   it "displays a submit button" do
    #     expect(page).to have_button("Submit")
    #   end

    #   it "does not ask for contact information" do
    #     expect(page).to have_no_text("Contact Information")
    #   end

    # end

    context "on the final step before submitting when contact information is required" do
      before :all do
        choose "Stage for Delivery"
        click_button "Continue"
        # click_button "Continue"
      end

      after :all do
        reset_access_page
      end

      it "displays current contact information" do
        account_form = page.find('.account-form')
        expect(account_form).to have_text("Earthdata Search (patrick+edsc@element84.com)")
        expect(account_form).to have_text("Organization: EDSC")
        expect(account_form).to have_text("Country: United States")
        expect(account_form).to have_text("Affiliation: OTHER")
        expect(account_form).to have_text("Study Area: OTHER")
        expect(account_form).to have_text("User Type: PRODUCTION_USER")

        expect(account_form).to have_link('Edit Profile in Earthdata Login')
      end

      it 'displays a "submit" button' do
        expect(page).to have_content "Submit"
      end

      # it 'displays a "back" button' do
      #   within(".data-access-content") do
      #     expect(page).to have_content "Back"
      #   end
      # end

      # context 'clicking the "back" button' do
      #   before :all do
      #     click_button "Back"
      #   end

      #   after :all do
      #     click_button "Continue"
      #   end

      #   it 'displays the previous collection in the list' do
      #     expect(page).to have_content "Collection Only"
      #   end
      # end
    end
  end

  context 'when a collection has only a single download mechanism' do
    before(:all) do
      load_page :search, {project: [collection_with_one_option], view: :project}
      login
      click_button "Download project data"
      wait_for_xhr
    end

    it 'preselects the only option available' do
      find(:css, '#access-method-C1000000020-LANCEAMSR2-00').should be_checked
    end
  end

  context 'when a collection has two download mechanisms' do
    before(:all) do
      load_page :search, {project: [collection_with_two_options], view: :project}
      login
      click_button "Download project data"
      wait_for_xhr
    end

    it 'does not select either option' do
      find(:css, '#access-method-C179003620-ORNL_DAAC-00').should_not be_checked
      find(:css, '#access-method-C179003620-ORNL_DAAC-01').should_not be_checked
    end
  end

end
