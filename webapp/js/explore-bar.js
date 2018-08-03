var pathname = window.location.pathname;
var popEventListnerAdded = false;
var current_explore_by, previous_page;
var curr_gallery;
var curr_gallery_name;
var bar_open;
var galleries;

$(document).ready(function () {
  if (window.location.hash == "#editor") return; // Do not load the explore bar for editmode
  bar_open = $.urlParam("fromexplore") == "true";
  previous_page = (sessionStorage.getItem("previous_page") === null || !bar_open) ? null : sessionStorage.getItem("previous_page");
  sessionStorage.removeItem("previous_page");
  current_explore_by = (sessionStorage.getItem("explore_by") === null || !bar_open) ? "creator" : sessionStorage.getItem("explore_by");

  $("#" + current_explore_by + "-text").removeClass("hidden");
  $("#galleries .caret").hide();
  if (current_explore_by != "galleries") {
    $(".explore_button").removeClass("bold");
    $("#galleries .selected").removeClass("bold");
    $("#" + current_explore_by).addClass("bold");
    $("#galleries-text").addClass("hidden");
  } else {
    $(".explore_button").removeClass("bold");
    $("#galleries .selected").addClass("bold");
  }


  var projectsLoaded = false;
  $("#open_explore").click(function () {
    if(!projectsLoaded) {
        loadRelatedProjects();
        projectsLoaded = true;
    }

    $("#related-projects").animate({
      height: '160px'
    });
    $("#explore-header-open").removeClass("hidden");
    $("#explore-header-closed").addClass("hidden");
    bar_open = true;
    sessionStorage.setItem("explore", "true");
  });

  $("#explore-header").click(function () {
      if(!projectsLoaded) {
          loadRelatedProjects();
          projectsLoaded = true;
      }

      if (bar_open === false) {
        $("#related-projects").animate(
          {height: '160px'},
          function () {$(".carousel-control").show();}
        );
        $("#explore-header-open").removeClass("hidden");
        $("#explore-header-closed").addClass("hidden");

        bar_open = true;
        sessionStorage.setItem("explore", "true");
      }
  });


  $("#close").click(function (e) {
    e.preventDefault();
    $("#related-projects").animate(
      {height: '0px'}
    );
    $(".carousel-control").hide();
    bar_open = false;
    sessionStorage.setItem("explore", "false");
    $("#explore-header-open").addClass("hidden");
    $("#explore-header-closed").removeClass("hidden");
    return false;
  });

  $('.explore_button').click(function (e) {
    e.preventDefault();
    if ($(this).hasClass("disabled") === false) {
      var selected = $(this).attr("id");
      $(".explore-by-text").addClass("hidden");
      if (selected != "galleries") {
        $(".explore_button").removeClass("bold");
        $("#galleries .selected").removeClass("bold");
        $("#" + selected).addClass("bold");
        $(".explore-by-text").addClass("hidden");
        $("#" + selected + "-text").removeClass("hidden");
      } else {
        $(".explore_button").removeClass("bold");
        $("#galleries .selected").addClass("bold");
      }
      current_explore_by = selected;
      $(".list-container").addClass("hidden");
      $(".list-container").scrollLeft(0);
      $("#" + selected + "-list").removeClass("hidden");
      sessionStorage.setItem("explore_by", selected);
      if (selected != "galleries") {
        sessionStorage.removeItem("gallery_id");
      }
    }
    return false;
  });


  $("#galleries .dropdown-toggle").click(function (e) {
    if ($("#galleries .dropdown-menu li:not(.hide)").length > 0) {
      $("#explore-buttons .dropdown").toggleClass('open');
    }
    $(".explore-by-text").addClass("hidden");
    $("#galleries-text").removeClass("hidden");
    e.preventDefault();
    if ($(this).parent().hasClass("disabled") === false) {
      var selected = $(this).parent().attr("id");
      if (selected != "galleries") {
        $(".explore_button").removeClass("bold");
        $("#galleries .selected").removeClass("bold");
        $("#" + selected).addClass("bold");
      } else {
        $(".explore_button").removeClass("bold");
        $("#galleries .selected").addClass("bold");
      }
      current_explore_by = selected;
      $(".list-container").addClass("hidden");
      $(".list-container").scrollLeft(0);
      $("#" + selected + "-list").removeClass("hidden");
      sessionStorage.setItem("explore_by", selected);
    }
    return false;
  });



  $(".project-item").on("click", function () {
    data.project.id = $(this).attr("project_id");
    data.project.creator = $(this).attr("creator");
    data.project.title = $(this).attr("title");
    window.location = "../" + data.project.id + "/?mode=player&fromexplore=true";
  });

  if (bar_open) {
    $('#explore-header').click();
    $("#" + current_explore_by + "-list").removeClass("hidden");
    $("#explore-header-open").removeClass("hidden");
    $("#explore-header-closed").addClass("hidden");
    $("#related-projects").css("height", "160px");
    $(".carousel-control").show();
  }



});

function loadRelatedProjects() {
  curr_gallery = (sessionStorage.getItem("gallery_id") === null && sessionStorage.getItem("explore_by") != "galleries") ? "" : sessionStorage.getItem("gallery_id");
  curr_gallery_name = (sessionStorage.getItem("gallery_name") === null) ? "" : sessionStorage.getItem("gallery_name");
  if (curr_gallery) {
    gal_url = "?id=" + curr_gallery;
    $.ajax({
      url: "../../explore/ajax/new/" + data.project.id + "/gallery_by_id" + gal_url,
      success: function (d) {
        if (d != "" && d.length > 20) {
          $("#explore-buttons #galleries").removeClass("");
          $("#galleries .selected").text("Studio");
          $("#galleries-list").html(d);
          var num_projects = $("#galleries-list .project-item").length;
          $("#galleries-list").css("width", num_projects * 176);
          $("#related-projects [project_id=" + $.urlParam("id") + "]").remove();
        } else {
          $("#explore-buttons #galleries").addClass("disabled");
          $("#galleries.caret").hide();
          $("#galleries-list").html("<p class='no-results'>no related projects by gallery</p>");
          $(".right").addClass("off");
        }
      }
    });
  }

  
  $.ajax({
    url: "../../explore/ajax/new/" + data.project.id + "/creator",
    success: function (d) {
      $("#creator-list").addClass("hidden");
      if (d != "") {
        $("#explore-buttons #creator").removeClass("");
        $("#creator-list").html(d);
        $('.carousel').carousel();
        var num_projects = $("#creator-list .project-item").length;
        $("#related-projects [project_id=" + $.urlParam("id") + "]").remove();
        $("#creator-list").css("width", num_projects * 176);
        $("#creator-text").html("More projects by <a href='../../users/" + data.project.creator + "'>" + data.project.creator + "</a>");
        if ($("#creator-list").children().length === 0) {
          $(".dropdown-menu #creator").addClass("");
          $("#explore-buttons #creator").addClass("disabled");
          //$(".right").addClass("off")
          $("#creator-list").html("<p class='no-results'>no related projects by creator</p>");
        }
      } else {
        $("#explore-buttons #creator").addClass("disabled");
        $("#creator-list").html("<p class='no-results'>no projects by same creator</p>");
        //$(".right").addClass("off")
      }
      if (current_explore_by == "creator") $("#creator-list").removeClass("hidden");
    }
  });

  $.ajax({
    url: "../../explore/ajax/new/" + data.project.id + "/remixes",
    success: function (d) {
      if (d != "" && d.length > 20) {
        $("#explore-buttons #remixes").removeClass("");
        $("#remixes-list").html(d);
        var num_projects = $("#remixes-list .project-item").length;
        $("#remixes-list").css("width", num_projects * 176);
        $("#remixes-text").html("Remixes of " + data.project.title);
      } else {
        $("#explore-buttons #remixes").addClass("disabled");
        $("#remixes-list").html("<p class='no-results'>no remixes of this project</p>");
        //$(".right").addClass("off")
      }
    }
  });

}

resetRelatedList = function () {
  $("#related-projects .list-container").addClass("hidden");
  $("#related-projects .list-container").html('<div class="ajax-loader">');
  $("#related-projects #" + current_explore_by + "-list").removeClass("hidden");
};
