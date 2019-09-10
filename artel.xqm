module namespace artel = "http://karlowka.de/artel";
import module namespace functx = "http://www.functx.com";
import module namespace score ='http://karlowka.de/score' at "score.xqm";
import module namespace request = "http://exquery.org/ns/request";


declare variable $artel:db-name := 'artel';
declare variable $artel:url :=  db:open('artel')/config/host/text();
declare variable $artel:title := 'Radical Feedback'; 
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
  %updating
function artel:new-board($hash) as empty-sequence ()
{
  let $a := 
      <board master="{$hash[1]}" common = "{$hash[2]}" time = "{current-dateTime()}">
        <members/>
      </board>
  return
       insert node $a into db:open($artel:db-name)/main
};

declare
  %updating
function artel:members-to-db ($members, $master) as empty-sequence ()
{
    replace node db:open($artel:db-name)/main/board[@master/data()=$master]/members with $members,
    delete node db:open($artel:db-name)/main/board[@master/data()=$master]/values,
    insert node 
        for $i in $members/member/text()
        return 
            <values person="{$i}"/>
        into db:open($artel:db-name)/main/board[@master/data()=$master]
};

declare
  %updating 
  %rest:path("/artel/new-board")
  %rest:GET
function artel:create-hash () 
{
  let $hash := (random:uuid(), random:uuid()) 
  return               
   artel:create-bord($hash, 'artel/master')
};

declare
  %updating
  %rest:path("/artel/members")
  %rest:query-param("members", "{$members}")
  %rest:query-param("master", "{$master}")
  %rest:query-param("url-redirect", "{$url-redirect}", "artel/master")
  %rest:GET
function artel:input-members ($members, $master, $url-redirect) 
{
  artel:members-to-db (
    <members>{
      for $i in tokenize($members, ",")
      order by $i
      return 
        <member>{normalize-space($i)}</member>}
    </members>,
    $master
  ),
  db:output(
    web:redirect(
      $artel:url || $url-redirect,
      map { "master": $master , "message":"Участники опроса успешно зарегистрированы" }
    )
  )
};

declare
  %updating
function artel:create-bord( $hash, $url-redirect )
{            
 artel:new-board( $hash ),
 db:output(
   web:redirect(
     $artel:url || $url-redirect,
     map {"master": $hash[1], "common":$hash[2], "message":"Новый опрос успешно создан"}
   )
 )
};

declare
  %updating
  %rest:path("/artel/input/values")
  %rest:GET 
function artel:input-values ()
{ 
  let $values :=
    <values person="{request:parameter('ФИО')}">
    {
      for $a in request:parameter-names()[(data() != "common") and (data() != "ФИО")]
      order by $a
      return <row имя="{$a}">{request:parameter($a)}</row>
    }
    </values>
  return
    replace node db:open($artel:db-name)/main/board[@common=request:parameter("common")]/values[@person/data()=request:parameter("ФИО")] with $values,
    
    let $message := "Товарищ " || request:parameter("ФИО") || ", Ваши оценки успешно записаны"
    return
      db:output(web:redirect($artel:url || 'artel/input', map { "common":request:parameter("common"), "message":$message}))
};

declare
  %rest:path("/artel/master")
  %rest:GET
  %rest:query-param("master", "{$master}")
  %rest:query-param("message", "{$message}")
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
function artel:edit-board($master, $message)
{
  let $common := db:open($artel:db-name)/main/board[@master/data()=$master]/@common/data()
  let $href_master := "master?" || 'master=' || request:parameter("master") 
  let $href_common := "input?" || 'common=' || $common
  let $href_result := "result?" || 'common=' || $common
  return
  <html>
    {$artel:head}
    <body>
      <div class="container-fluid text-center">    
        <div class="row content">
          <div class="col-sm-9 text-left"> 
              <h1>{$artel:title}</h1>
              <p><i>{$message}</i></p>
              <p><a href= "{$href_master }">Ссылка для ввода списка участников</a> (сохраните её на всякий случай)</p>
              <a href= "{$href_common }">Ссылка для ввода участником оценок</a>
              <p>{if (score:is-complete ($common )) then (<a href= "{$href_result }">Ссылка для просмотра результатов</a>) else (<span><u>Ссылка для просмотра результатов пока не доступна</u> (введены оценки {score:complete ($common )} участника(ов))</span>)}</p>
              <form enctype="multipart/form-data" action = 'members' method="get">
                <p>Укажите участников (через запятую):</p>
                <p><textarea name="members"></textarea></p>
                <input type="hidden" name="master" value="{$master}"/>
                <input type="submit"/>
              </form>
              <p>Зарегистрированы участники:</p>
              {if (db:open($artel:db-name)/main/board[@master/data()=$master]/members/member[text()])
              then (
              <ul>
                {for $i in db:open($artel:db-name)/main/board[@master/data()=$master]/members/member[text()]
                  return <li>{$i/text()}</li>
                }
              </ul>)
              else (<p><i>пока нет участников...</i></p>)}
          </div>
        </div>
      </div>  
    </body>
  </html>
};

declare
  %rest:path("/artel/input")
  %rest:GET
  %rest:query-param("common", "{$common}")
  %rest:query-param("message", "{$message}")
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
function artel:input-common($common, $message)
{
  let $href_result := $artel:url || "artel/result?" || 'common=' || $common
  return
  <html>
    {$artel:head}
    <body>
      <div class="container-fluid text-center">    
        <div class="row content">
          <div class="col-sm-9 text-left"> 
            <h1>{$artel:title}</h1>
            <p><i>{$message}</i></p>
            <p>Это форма для ввода ваших оценок</p>
            <p>{if (score:is-complete ($common )) then (<a href= "{$href_result }">Ссылка для просмотра результатов</a>) else (<span><u>Ссылка для просмотра результатов пока не доступна</u> (введены оценки {score:complete ($common )} участника(ов))</span>)}</p>
            <p>Оцените вклад участника (в %):</p>
            <form enctype="multipart/form-data" action = "{$artel:url || 'artel/input/values'}" method="get">
              <table>
              
                {for $i in db:open($artel:db-name)/main/board[@common/data()=replace($common, " ", "+")]/members/member[text()]
                  return  <tr><td style="padding: 5px;">{$i/text()}</td><td><input name="{$i/text()}" type = "text"/> %</td></tr>
                }
                <tr>
                  <td style="padding: 5px;">Кто вы:</td>
                  <td style="padding: 5px;">
                    <select name="ФИО" style = "width: 200px" >{
                      for $i in db:open($artel:db-name)/main/board[@common/data()=$common]/members/member[text()]/text()
                      return <option  value = "{$i}">{$i}</option>}
                    </select>  
                  </td>
                </tr>
              </table>
              <input type="hidden" name="common" value="{$common}"/>
              <input type="submit"/>  
            </form>
          </div>
        </div>
      </div>  
    </body>
  </html>
};

declare
  %rest:path("/artel/result")
  %rest:GET
  %rest:query-param("common", "{$common}")
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
function artel:result($common)
{
  
  let $data := db:open("artel")/main/board[@common=$common]
  let $result := score:result($data)
  return 
  <html>
    <head>{$artel:head}</head>
    <body>
      <div class="container-fluid text-center">    
        <div class="row content">
          <div class="col-sm-9 text-left"> 
            <h1>{$artel:title}</h1>
            <p><i>Результаты оценки</i></p>
            {
              score:final-table( 
                $result,
                ("persons", "self_evaluation", "second", "diff", "penalty_index", "final_evaluation")
              )
            }
            <p>Срендняя пере-(недо-)оценка { round( $result?diff_avg, 1 ) }</p>
        </div>
      </div>
    </div>  
    </body>
  </html>
};

declare
  %rest:path("/artel")
  %rest:GET
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
function artel:artel()
{
  <html>
    {$artel:head}
  <body>
    <div class="container-fluid text-center">    
      <div class="row content">
        <div class="col-sm-9 text-left"> 
          <h1>{$artel:title}</h1>
          <p>Для регистрации новой панели нажмите ... </p>
          <form enctype="multipart/form-data" action = "{ $artel:url || '/artel/new-board' }" method="get">
            <input type="submit" value = "создать"/>
          </form>
        </div>
      </div>
    </div>  
  </body>
</html>
};