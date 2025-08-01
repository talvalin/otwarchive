require "spec_helper"

describe CollectionItemsController do
  include LoginMacros
  include RedirectExpectationHelper

  let(:user) { create(:user) }
  let(:collection) { create(:collection) }

  describe "GET #index" do
    let(:pseud) { user.default_pseud }

    let(:rejected_by_collection_work) { create(:work, authors: [pseud]) }
    let(:rejected_by_user_work) { create(:work, authors: [pseud]) }
    let(:approved_work) { create(:work, authors: [pseud]) }
    let(:unreviewed_by_user_work) { create(:work, authors: [pseud]) }
    let(:unreviewed_by_collection_work) { create(:work, authors: [pseud]) }

    let!(:rejected_by_collection_work_item) { collection.collection_items.create(item: rejected_by_collection_work) }
    let!(:rejected_by_user_work_item) { collection.collection_items.create(item: rejected_by_user_work) }
    let!(:approved_work_item) { collection.collection_items.create(item: approved_work) }
    let!(:unreviewed_by_user_work_item) { collection.collection_items.create(item: unreviewed_by_user_work) }
    let!(:unreviewed_by_collection_work_item) { collection.collection_items.create(item: unreviewed_by_collection_work) }

    before do
      rejected_by_collection_work_item.rejected_by_collection!
      rejected_by_user_work_item.rejected_by_user!
      unreviewed_by_user_work_item.unreviewed_by_user!
      unreviewed_by_collection_work_item.unreviewed_by_collection!
    end

    context "with collection params" do
      context "when the user is not a maintainer" do
        it "redirects and shows an error message" do
          fake_login_known_user(user)
          get :index, params: { collection_id: collection.id }
          it_redirects_to_with_error(collections_path, "You don't have permission to see that, sorry!")
        end
      end

      context "with no additional params" do
        let(:owner) { collection.owners.first.user }

        it "includes items awaiting collection approval" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_collection_work_item
        end

        it "excludes items that are invited, approved by both parties, or rejected by the collection or user" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name }
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
        end
      end

      context "with params[:status] = \"rejected_by_collection\"" do
        let(:owner) { collection.owners.first.user }

        it "includes items rejected by the collection" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "rejected_by_collection" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include rejected_by_collection_work_item
        end

        it "excludes items that are invited, approved by both parties, rejected by the user, or awaiting approval from collection" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "rejected_by_collection" }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"rejected_by_user\"" do
        let(:owner) { collection.owners.first.user }

        it "includes items rejected by the user" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "rejected_by_user" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include rejected_by_user_work_item
        end

        it "excludes items that are invited, approved by both parties, rejected by the collection, or awaiting approval from collection" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "rejected_by_user" }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"unreviewed_by_user\"" do
        let(:owner) { collection.owners.first.user }

        it "includes invited items" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "unreviewed_by_user" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_user_work_item
        end

        it "excludes items that are approved, rejected by the collection or user, or awaiting approval from collection" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "unreviewed_by_user" }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"approved\"" do
        let(:owner) { collection.owners.first.user }

        it "includes approved items" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "approved" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include approved_work_item
        end

        it "excludes items that are invited, rejected by the collection or user, or awaiting approval from collection" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, status: "approved" }
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with other params" do
        let(:owner) { collection.owners.first.user }

        it "includes items awaiting collection approval" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, fake: true }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_collection_work_item
        end

        it "excludes items that are invited, approved by both parties, or rejected by the collection or user" do
          fake_login_known_user(owner)
          get :index, params: { collection_id: collection.name, fake: true }
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
        end
      end
    end

    context "with user params" do
      context "with no additional params" do
        it "includes invited items" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_user_work_item
        end

        it "excludes items that are approved by both parties, rejected by the collection or user, or awaiting approval from collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"unreviewed_by_collection\"" do
        it "includes items awaiting collection approval" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "unreviewed_by_collection" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_collection_work_item
        end

        it "excludes items that are invited, approved by both parties, or rejected by the collection or user" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "unreviewed_by_collection" }
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
        end
      end

      context "with params[:status] = \"rejected_by_collection\"" do
        it "includes items rejected by the collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "rejected_by_collection" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include rejected_by_collection_work_item
        end

        it "excludes items that are invited, approved by both parties, rejected by the user, or awaiting approval from collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "rejected_by_collection" }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"rejected_by_user\"" do
        it "includes items rejected by the user" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "rejected_by_user" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include rejected_by_user_work_item
        end

        it "excludes items that are invited, approved by both parties, rejected by the collection, or awaiting approval from collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "rejected_by_user" }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with params[:status] = \"approved\"" do
        it "includes approved items" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "approved" }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include approved_work_item
        end

        it "excludes items that are invited, rejected by the collection or user, or awaiting approval from collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, status: "approved" }
          expect(assigns(:collection_items)).not_to include unreviewed_by_user_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end

      context "with other params" do
        it "includes invited items" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, fake: true }
          expect(response).to have_http_status(:success)
          expect(assigns(:collection_items)).to include unreviewed_by_user_work_item
        end

        it "excludes items that are approved by both parties, rejected by the collection or user, or awaiting approval from collection" do
          fake_login_known_user(user)
          get :index, params: { user_id: user.login, fake: true }
          expect(assigns(:collection_items)).not_to include approved_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_collection_work_item
          expect(assigns(:collection_items)).not_to include rejected_by_user_work_item
          expect(assigns(:collection_items)).not_to include unreviewed_by_collection_work_item
        end
      end
    end
  end

  describe "GET #new" do
    context "denies access for work that isn't visible to user" do
      subject { get :new, params: { work_id: work.id } }
      let(:work) { create(:work) }
      let(:success) { expect(response).to render_template("new") }
      let(:redirects_to_login) do
        it_redirects_to_with_error(
          new_user_session_path,
          "Sorry, you don't have permission to access the page you were trying to reach. Please log in."
        )
      end
      let(:success_admin) { redirects_to_login }

      include_examples "denies access for work that isn't visible to user"

      it "redirects to login if logged out" do
        subject
        redirects_to_login
      end
    end
  end

  describe "POST #create" do
    context "creation" do
      let(:collection) { FactoryBot.create(:collection) }

      it "fails if collection names missing" do
        post :create, params: { collection_id: collection.id }
        it_redirects_to_with_error(root_path, "What collections did you want to add?")
      end

      it "fails if items missing" do
        post :create, params: { collection_names: collection.name, collection_id: collection.id }
        it_redirects_to_with_error(root_path, "What did you want to add to a collection?")
      end
    end

    context "when logged in as the collection maintainer" do
      before { fake_login_known_user(collection.owners.first.user) }

      context "when the item is a work" do
        let(:work) { create(:work) }

        let(:params) do
          {
            collection_names: collection.name,
            work_id: work.id
          }
        end

        context "when the creator does not allow invitations" do
          it "does not create an invitation" do
            post :create, params: params
            it_redirects_to_with_error(work, "This item could not be invited.")
            expect(work.reload.collections).to be_empty
          end
        end

        context "when the creator allows invitations" do
          before do
            work.users.each { |user| user.preference.update!(allow_collection_invitation: true) }
          end

          it "creates an invitation" do
            post :create, params: params
            it_redirects_to_simple(work)
            expect(work.reload.collections).to include(collection)
          end
        end
      end
    end

    context "as an archivist" do
      let(:archivist) { create(:archivist) }
      let(:work) { create(:work) }

      let(:collection) do
        create(:collection, owner: archivist.default_pseud)
      end

      let(:params) do
        {
          collection_names: collection.name,
          work_id: work.id
        }
      end

      before do
        fake_login_known_user(archivist)
      end

      context "when the item's creator does not allow collection invitations" do
        it "adds the item anyway" do
          post :create, params: params
          it_redirects_to_with_notice(work, "Added to collection(s): #{collection.title}.")
          expect(work.reload.collections).to include(collection)
        end
      end

      context "when the item's creator allows collection invitations" do
        it "adds the item" do
          post :create, params: params
          it_redirects_to_with_notice(work, "Added to collection(s): #{collection.title}.")
          expect(work.reload.collections).to include(collection)
        end
      end
    end
  end

  describe "PATCH #update_multiple" do
    let(:collection) { create(:collection) }
    let(:work) { create(:work) }
    let(:item) { create(:collection_item, collection: collection, item: work) }

    let(:attributes) { { remove: "1" } }

    describe "on the user collection items page for the work's owner" do
      let(:work_owner) { work.pseuds.first.user }

      let(:params) do
        {
          user_id: work_owner.login,
          collection_items: {
            item.id => attributes
          }
        }
      end

      context "when logged out" do
        before { fake_logout }

        it "errors and redirects" do
          patch :update_multiple, params: params
          it_redirects_to_with_error(work_owner, "You don't have permission to do that, sorry!")
        end
      end

      context "when logged in as a random user" do
        before { fake_login }

        it "errors and redirects" do
          patch :update_multiple, params: params
          it_redirects_to_with_error(work_owner, "You don't have permission to do that, sorry!")
        end
      end

      context "when logged in as the collection owner" do
        before { fake_login_known_user(collection.owners.first.user) }

        it "errors and redirects" do
          patch :update_multiple, params: params
          it_redirects_to_with_error(work_owner, "You don't have permission to do that, sorry!")
        end
      end

      context "when logged in as the work's owner" do
        before { fake_login_known_user(work_owner) }

        context "setting user_approval_status" do
          let(:attributes) { { user_approval_status: "rejected" } }

          it "updates the collection item and redirects" do
            patch :update_multiple, params: params
            expect(item.reload.user_approval_status).to eq("rejected")
            it_redirects_to_with_notice(user_collection_items_path(work_owner),
                                        "Collection status updated!")
          end
        end

        context "setting remove" do
          let(:attributes) { { remove: "1" } }

          it "deletes approved collection item and redirects" do
            patch :update_multiple, params: params
            expect { item.reload }.to \
              raise_exception(ActiveRecord::RecordNotFound)
            it_redirects_to_with_notice(user_collection_items_path(work_owner),
                                        "Collection status updated!")
          end

          it "deletes item rejected by user and redirects" do
            item.rejected_by_user!

            patch :update_multiple, params: params
            expect { item.reload }.to \
              raise_exception(ActiveRecord::RecordNotFound)
            it_redirects_to_with_notice(user_collection_items_path(work_owner),
                                        "Collection status updated!")
          end

          it "deletes item rejected by collection and redirects" do
            item.rejected_by_collection!

            patch :update_multiple, params: params
            expect { item.reload }.to \
              raise_exception(ActiveRecord::RecordNotFound)
            it_redirects_to_with_notice(user_collection_items_path(work_owner),
                                        "Collection status updated!")
          end
        end

        {
          collection_approval_status: "rejected",
          unrevealed: true,
          anonymous: true
        }.each_pair do |field, value|
          context "setting #{field}" do
            let(:attributes) { { field => value } }

            it "throws an error and doesn't update" do
              expect do
                patch :update_multiple, params: params
              end.to raise_exception(ActionController::UnpermittedParameters)
              expect(item.reload.send(field)).not_to eq(value)
            end
          end
        end
      end
    end

    describe "on the collection items page for the work's collection" do
      let(:params) do
        {
          collection_id: collection.name,
          collection_items: {
            item.id => attributes
          }
        }
      end

      context "when logged out" do
        before { fake_logout }

        it "errors and redirects" do
          patch :update_multiple, params: params
          it_redirects_to_with_error(collection, "You don't have permission to do that, sorry!")
        end
      end

      context "when logged in as a random user" do
        before { fake_login }

        it "errors and redirects" do
          patch :update_multiple, params: params
          it_redirects_to_with_error(collection, "You don't have permission to do that, sorry!")
        end
      end

      context "when logged in as a maintainer" do
        before { fake_login_known_user(collection.owners.first.user) }

        {
          collection_approval_status: "rejected",
          unrevealed: true,
          anonymous: true
        }.each_pair do |field, value|
          context "setting #{field}" do
            let(:attributes) { { field => value } }

            it "updates the collection item and redirects" do
              patch :update_multiple, params: params
              expect(item.reload.send(field)).to eq(value)
              it_redirects_to_with_notice(collection_items_path(collection),
                                          "Collection status updated!")
            end
          end
        end

        context "setting remove" do
          let(:attributes) { { remove: "1" } }

          it "deletes approved collection item and redirects" do
            patch :update_multiple, params: params
            expect { item.reload }.to \
              raise_exception(ActiveRecord::RecordNotFound)
            it_redirects_to_with_notice(collection_items_path(collection),
                                        "Collection status updated!")
          end

          context "when item is rejected by user" do
            context "when maintainer is not collectible's creator" do
              before { item.rejected_by_user! }

              it "silently fails to delete item" do
                patch :update_multiple, params: params
                expect(collection.collection_items).to include item
                it_redirects_to_with_notice(collection_items_path(collection),
                                            "Collection status updated!")
              end
            end

            context "when maintainer is also collectible's creator" do
              let(:work) { create(:work, authors: [collection.owners.first]) }

              before { item.rejected_by_user! }

              it "deletes item and redirects" do
                patch :update_multiple, params: params
                expect { item.reload }.to \
                  raise_exception(ActiveRecord::RecordNotFound)
                it_redirects_to_with_notice(collection_items_path(collection),
                                            "Collection status updated!")
              end
            end
          end
        end

        context "setting user_approval_status" do
          let(:attributes) { { user_approval_status: "rejected" } }

          it "throws an error and doesn't update" do
            expect do
              patch :update_multiple, params: params
            end.to raise_exception(ActionController::UnpermittedParameters)
            expect(item.reload.user_approval_status).not_to eq("rejected")
          end
        end
      end
    end

    describe "on the collection items page for a different user" do
      let(:user) { create(:user) }
      let(:params) do
        {
          user_id: user.login,
          collection_items: {
            item.id => { user_approval_status: "rejected" }
          }
        }
      end

      before { fake_login_known_user(user) }

      it "silently fails to update the collection item" do
        patch :update_multiple, params: params
        expect(item.reload.user_approval_status).not_to eq("rejected")
        it_redirects_to_with_notice(user_collection_items_path(user),
                                    "Collection status updated!")
      end
    end

    describe "on the collection items page for a different collection" do
      let(:other_collection) { create(:collection) }
      let(:params) do
        {
          collection_id: other_collection.name,
          collection_items: {
            item.id => { collection_approval_status: "rejected" }
          }
        }
      end

      before { fake_login_known_user(other_collection.owners.first.user) }

      it "silently fails to update the collection item" do
        patch :update_multiple, params: params
        expect(item.reload.collection_approval_status).not_to eq("rejected")
        it_redirects_to_with_notice(collection_items_path(other_collection),
                                    "Collection status updated!")
      end
    end
  end
end
