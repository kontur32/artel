module namespace artel = "http://karlowka.de/artel";

declare variable $artel:head := 
      <head>
        <title>Radical Feedback</title>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
      </head>;

declare 
  %private
  %rest:path( "/artel/monitor" )
  %output:method( "xhtml" )
function artel:monitor(){
  <html>
    {$artel:head}
    <body>
      <div class="container-fluid text-center">    
        <div class="row content">
          <div class="col-sm-2 text-left"/>
          <div class="col-sm-8 text-left">
          { let $boards := db:open("artel")/main/board
            let $boardsToday := $boards[ days-from-duration( current-dateTime() - xs:dateTime( @time ) ) < 2 ]
            let $completeBoardsTotal :=  $boards[ count ( members/member ) = count( values ) and count ( members/member ) > 0 ]
            let $completeBoardsToday := $completeBoardsTotal[ days-from-duration( current-dateTime() - xs:dateTime( @time ) ) < 2 ]
            return
            (
              <h3>Голосований зарегистрировано/завершено/участников</h3>,
              <lu>
                <li>всего: { count( $boards )}/{ count( $completeBoardsTotal )}/{ count( $completeBoardsTotal/members/member )}</li>
                <li>сегодня: { count( $boardsToday )}/{ count( $completeBoardsToday )}/{ count( $completeBoardsToday/members/member ) }</li>
              </lu>
            )
          }
          </div>
         <div class="col-sm-2 text-left"/>
       </div>
     </div>
   </body>
  </html>    
};