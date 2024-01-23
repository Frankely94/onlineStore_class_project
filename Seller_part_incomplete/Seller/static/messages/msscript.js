
const  sideMenu = document.querySelector('aside');
const menuBtn = document.querySelector('#menu_bar');
const closeBtn = document.querySelector('#close_btn');

const themeToggler = document.querySelector('.theme-toggler');

menuBtn.addEventListener('click',()=>{
       sideMenu.style.display = "block"
})
closeBtn.addEventListener('click',()=>{
    sideMenu.style.display = "none"
})

themeToggler.addEventListener('click', () => {
    document.body.classList.toggle('dark-theme'); // Toggle the 'dark-theme' class on the body
    themeToggler.children[0].classList.toggle('active'); // Toggle the 'active' class on the first span
    themeToggler.children[1].classList.toggle('active'); // Toggle the 'active' class on the second span
  });

$(document).ready(function() {
    var socket = io.connect("http://localhost:8000")
    socket.on('connect',function() {
        socket.send("User connected!");
    });
    socket.on('message',function(data){
        $('#messages').append($('<p>').text(data));
    });

    $('#sendBtn').on('click',function() {
        socket.send($('#username').val()+ ': '+ $('#message').val());
        $('#message').val('');
    });
});