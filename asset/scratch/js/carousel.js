/* 
 * Based on bootstrap-carousel.js 
 * http://twitter.github.com/bootstrap/javascript.html#carousel
*/

!function( $ ){

  "use strict"

 /* CAROUSEL CLASS DEFINITION
  * ========================= */

  var Carousel = function (element, options) {
    this.$element = $(element)
    this.$arrowLeft = this.$element.find('.arrow-left');
    this.$arrowRight = this.$element.find('.arrow-right');
    this.$scrollDiv = this.$element.find('.carousel-inner');
      //.on('scroll.carousel', $.proxy(this.toggleArrows, this));

    var $items = this.$scrollDiv.find('li');
    var $container = this.$scrollDiv.find('ul');
    $container.width($items.outerWidth(true)*$items.size());
    this.scrollPageWidth = this.$scrollDiv.width() + parseInt($items.css('padding-right'), 10) - 10;
    this.scrollMax = $container.width() - this.scrollPageWidth; 
    this.options = $.extend({}, $.fn.carousel.defaults, options)
    this.options.slide && this.slide(this.options.slide)
    
  }
  Carousel.prototype = {

   next: function () {
      if (this.sliding) return
      return this.slide('next')
    }

  , prev: function () {
      if (this.sliding) return
      return this.slide('prev')
    }
  
  , toggleArrows: function(newPos) {
      if(newPos <= 0) {
        this.$arrowLeft.addClass('off').removeClass('on');
        return;
      } else if (newPos >= this.scrollMax) {
        this.$arrowRight.addClass('off').removeClass('on');
        return;
      }
      this.$arrowRight.removeClass('off').addClass('on');
      this.$arrowLeft.removeClass('off').addClass('on');
    }  

  , slide: function (type, next) {
    var curPos = this.$scrollDiv.scrollLeft();
    var increment = type == 'next' ? this.scrollPageWidth : - this.scrollPageWidth;
    var newPos = curPos + increment;
     
    this.toggleArrows(newPos);
    this.sliding = true;
    this.$element.find('.carousel-inner').animate({
      scrollLeft: curPos + increment,
    }, 800, 'swing', $.proxy(function() {
      this.sliding = false;
    }, this));

      return this
    }
  }


 /* CAROUSEL PLUGIN DEFINITION
  * ========================== */

  $.fn.carousel = function ( option ) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('carousel')
        , options = typeof option == 'object' && option
      if (!data) $this.data('carousel', (data = new Carousel(this, options)))
      if (typeof option == 'number') data.to(option)
      else if (typeof option == 'string' || (option = options.slide)) data[option]()
    })
  }

  $.fn.carousel.defaults = {
  }

  $.fn.carousel.Constructor = Carousel


 /* CAROUSEL DATA-API
  * ================= */

  $(function () {
    $('body').on('click.carousel.data-api', '[data-slide]', function ( e ) {
      var $this = $(this), href
        , $target = $($this.attr('data-target') || (href = $this.attr('href')) && href.replace(/.*(?=#[^\s]+$)/, '')) //strip for ie7
        , options = !$target.data('modal') && $.extend({}, $target.data(), $this.data())
      $target.carousel(options)
      e.preventDefault()
    })
  })

}( window.jQuery );
