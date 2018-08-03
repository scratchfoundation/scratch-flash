function is_tag_valid(tag) {
  var re = /[!"#\$%&\'\(\)\*\+,-.\/:;<=>\?@[\]^_`\{\|\}~]+/g;
  var non_anum = tag.match(re);
  if (non_anum != null && non_anum.length > 0) 
    return false;
  else 
    return true;
}